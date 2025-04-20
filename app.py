from flask import Flask, render_template, request, jsonify, redirect, url_for
import mysql.connector
from dotenv import load_dotenv
import os
from datetime import datetime

app = Flask(__name__)

# Load environment variables
load_dotenv()

# MySQL Configuration
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '',  # Empty password
    'database': 'hospital_management'
}

def get_db_connection():
    return mysql.connector.connect(**db_config)

@app.route('/')
def index():
    try:
        # Get counts for dashboard
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Get total patients (only count non-discharged patients)
        cursor.execute("""
            SELECT COUNT(*) as count 
            FROM Patients 
            WHERE is_admitted = 1 OR registration_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        """)
        patients_count = cursor.fetchone()['count']
        
        # Get total active doctors
        cursor.execute("""
            SELECT COUNT(*) as count 
            FROM Doctors 
            WHERE is_active = 1
        """)
        doctors_count = cursor.fetchone()['count']
        
        # Get today's appointments
        cursor.execute("""
            SELECT COUNT(*) as count 
            FROM Appointments 
            WHERE appointment_date = CURDATE() AND status = 'Scheduled'
        """)
        appointments_count = cursor.fetchone()['count']
        
        # Get available rooms
        cursor.execute("""
            SELECT COUNT(*) as count 
            FROM Rooms 
            WHERE status = 'Available'
        """)
        rooms_count = cursor.fetchone()['count']
        
        # Get recent appointments with more details
        cursor.execute("""
            SELECT a.*, 
                   p.first_name as patient_first_name, p.last_name as patient_last_name,
                   d.first_name as doctor_first_name, d.last_name as doctor_last_name
            FROM Appointments a
            JOIN Patients p ON a.patient_id = p.patient_id
            JOIN Doctors d ON a.doctor_id = d.doctor_id
            WHERE a.appointment_date >= CURDATE()
            ORDER BY a.appointment_date ASC, a.appointment_time ASC
            LIMIT 5
        """)
        recent_appointments = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return render_template('index.html', 
                             patients_count=patients_count,
                             doctors_count=doctors_count,
                             appointments_count=appointments_count,
                             rooms_count=rooms_count,
                             recent_appointments=recent_appointments)
    except Exception as e:
        return str(e), 500

@app.route('/patients')
def patients():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Get patients
        cursor.execute("SELECT * FROM Patients")
        patients = cursor.fetchall()
        
        # Get doctors for the prescription form
        cursor.execute("SELECT doctor_id, first_name, last_name, specialization FROM Doctors")
        doctors = cursor.fetchall()
        
        # Get departments for the form
        cursor.execute("SELECT * FROM departments")
        departments = cursor.fetchall()
        
        # Get available rooms for the form
        cursor.execute("""
            SELECT room_id, room_number, room_type, status 
            FROM rooms 
            WHERE status = 'Available'
            ORDER BY room_type, room_number
        """)
        rooms = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return render_template('patients.html', 
                             patients=patients, 
                             doctors=doctors, 
                             departments=departments,
                             rooms=rooms)
    except Exception as e:
        print("Error in patients route:", str(e))
        return str(e), 500

@app.route('/doctors')
def doctors():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Get doctors with department names
        cursor.execute("""
            SELECT d.*, dept.department_name 
            FROM Doctors d
            LEFT JOIN departments dept ON d.department_id = dept.department_id
        """)
        doctors = cursor.fetchall()
        
        # Get departments for the form
        cursor.execute("SELECT * FROM departments")
        departments = cursor.fetchall()
        
        cursor.close()
        conn.close()
        return render_template('doctors.html', doctors=doctors, departments=departments)
    except Exception as e:
        print("Error in doctors route:", str(e))
        return str(e), 500

@app.route('/appointments')
def appointments():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Get appointments with patient and doctor details
        cursor.execute("""
            SELECT a.*, p.first_name as patient_first_name, p.last_name as patient_last_name,
                   d.first_name as doctor_first_name, d.last_name as doctor_last_name
            FROM Appointments a
            JOIN Patients p ON a.patient_id = p.patient_id
            JOIN Doctors d ON a.doctor_id = d.doctor_id
        """)
        appointments = cursor.fetchall()
        
        # Get patients and doctors for the form
        cursor.execute("SELECT patient_id, first_name, last_name FROM Patients")
        patients = cursor.fetchall()
        
        cursor.execute("SELECT doctor_id, first_name, last_name, specialization FROM Doctors")
        doctors = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        # Get today's date in YYYY-MM-DD format
        today = datetime.now().strftime('%Y-%m-%d')
        
        return render_template('appointments.html', 
                             appointments=appointments,
                             patients=patients,
                             doctors=doctors,
                             today=today)
    except Exception as e:
        return str(e), 500

@app.route('/add_patient', methods=['POST'])
def add_patient():
    try:
        data = request.get_json()
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Convert is_admitted to integer (0 or 1)
        is_admitted = int(data.get('is_admitted', 0))
        
        cursor.execute("""
            INSERT INTO Patients (first_name, last_name, date_of_birth, 
                                gender, address, phone_number, email, blood_group, 
                                emergency_contact, room_number, is_admitted, 
                                registration_date)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (data['first_name'], data['last_name'], data['date_of_birth'], 
              data['gender'], data['address'], data['phone_number'], 
              data.get('email'), data.get('blood_group'), data['emergency_contact'], 
              data.get('room_number'), is_admitted, 
              datetime.now().strftime('%Y-%m-%d')))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/add_doctor', methods=['POST'])
def add_doctor():
    try:
        data = request.get_json()
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Generate a staff_id (you might want to implement a better ID generation system)
        staff_id = f"DOC{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        cursor.execute("""
            INSERT INTO Doctors (first_name, last_name, license_number, staff_id, 
                               department_id, specialization, phone_number, email, 
                               qualification, experience_years, joining_date, is_active)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (data['first_name'], data['last_name'], data['license_number'], 
              staff_id, data['department_id'], data['specialization'], 
              data['phone_number'], data.get('email'), data['qualification'], 
              data['experience_years'], data.get('joining_date', datetime.now().strftime('%Y-%m-%d')), 
              True))  # Set is_active to True by default
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/schedule_appointment', methods=['POST'])
def schedule_appointment():
    try:
        if request.method == 'POST':
            data = request.get_json()
            patient_id = data['patient_id']
            doctor_id = data['doctor_id']
            appointment_date = data['appointment_date']
            appointment_time = data['appointment_time']

            # Validate appointment date
            appointment_date_obj = datetime.strptime(appointment_date, '%Y-%m-%d').date()
            today = datetime.now().date()
            
            if appointment_date_obj < today:
                return jsonify({'success': False, 'error': 'Appointment date cannot be in the past'}), 400

            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO Appointments (patient_id, doctor_id, appointment_date, 
                                        appointment_time, status)
                VALUES (%s, %s, %s, %s, 'Scheduled')
            """, (patient_id, doctor_id, appointment_date, appointment_time))
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/delete_patient/<int:patient_id>', methods=['DELETE'])
def delete_patient(patient_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # First delete all appointments for this patient
        cursor.execute("DELETE FROM Appointments WHERE patient_id = %s", (patient_id,))
        
        # Then delete the patient
        cursor.execute("DELETE FROM Patients WHERE patient_id = %s", (patient_id,))
        
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/delete_doctor/<int:doctor_id>', methods=['DELETE'])
def delete_doctor(doctor_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # First remove doctor assignments from rooms
        cursor.execute("UPDATE rooms SET assigned_doctor_id = NULL WHERE assigned_doctor_id = %s", (doctor_id,))
        
        # Then delete all appointments for this doctor
        cursor.execute("DELETE FROM Appointments WHERE doctor_id = %s", (doctor_id,))
        
        # Finally delete the doctor
        cursor.execute("DELETE FROM Doctors WHERE doctor_id = %s", (doctor_id,))
        
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/delete_appointment/<int:appointment_id>', methods=['DELETE'])
def delete_appointment(appointment_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM Appointments WHERE appointment_id = %s", (appointment_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_prescriptions/<int:patient_id>')
def get_prescriptions(patient_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT p.*, CONCAT(d.first_name, ' ', d.last_name) as doctor_name
            FROM prescriptions p
            JOIN doctors d ON p.doctor_id = d.doctor_id
            WHERE p.patient_id = %s
            ORDER BY p.prescription_date DESC
        """, (patient_id,))
        
        prescriptions = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(prescriptions)
    except Exception as e:
        print("Error getting prescriptions:", str(e))  # Add logging
        return jsonify({'error': str(e)}), 500

@app.route('/get_bills/<int:patient_id>')
def get_bills(patient_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT * FROM Bills
            WHERE patient_id = %s
            ORDER BY bill_date DESC
        """, (patient_id,))
        
        bills = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(bills)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/add_prescription', methods=['POST'])
def add_prescription():
    try:
        if request.method == 'POST':
            data = request.get_json()
            patient_id = data['patient_id']
            doctor_id = data['doctor_id']
            prescription_date = data['prescription_date']
            medication = data['medication']
            dosage = data['dosage']
            instructions = data['instructions']

            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Insert the prescription
            cursor.execute("""
                INSERT INTO prescriptions (patient_id, doctor_id, prescription_date, 
                                        medication, dosage, instructions)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (patient_id, doctor_id, prescription_date, 
                  medication, dosage, instructions))
            
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'success': True})
    except Exception as e:
        print("Error adding prescription:", str(e))  # Add logging
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/add_bill', methods=['POST'])
def add_bill():
    try:
        if request.method == 'POST':
            data = request.get_json()
            patient_id = data['patient_id']
            bill_date = data.get('bill_date', datetime.now().strftime('%Y-%m-%d'))
            consultation_fee = float(data.get('consultation_fee', 0))
            medication_fee = float(data.get('medication_fee', 0))
            test_fee = float(data.get('test_fee', 0))
            room_charge = float(data.get('room_charge', 0))
            other_charges = float(data.get('other_charges', 0))
            payment_status = data.get('payment_status', 'Pending')

            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO Bills (patient_id, bill_date, consultation_fee, 
                                 medication_fee, test_fee, room_charge, 
                                 other_charges, payment_status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (patient_id, bill_date, consultation_fee, medication_fee, 
                  test_fee, room_charge, other_charges, payment_status))
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'success': True})
    except Exception as e:
        print("Error adding bill:", str(e))  # Add logging
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/rooms')
def rooms():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Get rooms with doctor information for consultation rooms
        cursor.execute("""
            SELECT r.*, 
                   CASE 
                       WHEN r.room_type = 'Consultation Room' THEN d.first_name
                       ELSE NULL
                   END as doctor_first_name,
                   CASE 
                       WHEN r.room_type = 'Consultation Room' THEN d.last_name
                       ELSE NULL
                   END as doctor_last_name
            FROM rooms r
            LEFT JOIN doctors d ON r.room_type = 'Consultation Room' AND r.assigned_doctor_id = d.doctor_id
            ORDER BY r.room_type, r.room_number
        """)
        rooms = cursor.fetchall()
        
        # Get doctors for the consultation room form
        cursor.execute("SELECT doctor_id, first_name, last_name FROM doctors")
        doctors = cursor.fetchall()
        
        cursor.close()
        conn.close()
        return render_template('rooms.html', rooms=rooms, doctors=doctors)
    except Exception as e:
        return str(e), 500

@app.route('/rooms', methods=['POST'])
def add_room():
    try:
        # Get basic room information
        room_number = request.form['room_number']
        # Map the form room_type to the exact ENUM values
        room_type_map = {
            'Patient': 'Patient Room',
            'Consultation': 'Consultation Room',
            'Waiting': 'Waiting Room',
            'Lab': 'Lab',
            'Other': 'Other'
        }
        room_type = room_type_map.get(request.form['room_type'], request.form['room_type'])
        status = request.form['status']
        description = request.form.get('description', '')

        # Initialize additional fields
        bed_count = None
        current_patients = 0
        max_patients = None
        assigned_doctor_id = None
        lab_name = None
        lab_contact = None
        equipment = None
        seating_capacity = None
        has_tv = False
        has_vending_machine = False
        other_room_type = None

        # Get type-specific fields
        if room_type == 'Patient Room':
            bed_count = request.form.get('bed_count')
            max_patients = request.form.get('max_patients')
            equipment = request.form.get('equipment')
        elif room_type == 'Consultation Room':
            assigned_doctor_id = request.form.get('assigned_doctor_id')
            equipment = request.form.get('equipment')
        elif room_type == 'Waiting Room':
            seating_capacity = request.form.get('seating_capacity')
            has_tv = request.form.get('has_tv') == 'true'
            has_vending_machine = request.form.get('has_vending_machine') == 'true'
        elif room_type == 'Lab':
            lab_name = request.form.get('lab_name')
            lab_contact = request.form.get('lab_contact')
            equipment = request.form.get('equipment')
        elif room_type == 'Other':
            other_room_type = request.form.get('other_room_type')

        conn = get_db_connection()
        cursor = conn.cursor()

        # Insert room with all possible fields
        cursor.execute("""
            INSERT INTO rooms (
                room_number, room_type, status, bed_count, current_patients, max_patients,
                assigned_doctor_id, lab_name, lab_contact, equipment, description,
                seating_capacity, has_tv, has_vending_machine, other_room_type
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            room_number, room_type, status, bed_count, current_patients, max_patients,
            assigned_doctor_id, lab_name, lab_contact, equipment, description,
            seating_capacity, has_tv, has_vending_machine, other_room_type
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)})

@app.route('/rooms/<int:room_id>', methods=['DELETE'])
def delete_room(room_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM rooms WHERE room_id = %s", (room_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)})

@app.route('/get_patient/<int:patient_id>')
def get_patient(patient_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM Patients WHERE patient_id = %s", (patient_id,))
        patient = cursor.fetchone()
        cursor.close()
        conn.close()
        return jsonify(patient)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/update_patient/<int:patient_id>', methods=['POST'])
def update_patient(patient_id):
    try:
        data = request.form
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE Patients 
            SET first_name = %s, last_name = %s, date_of_birth = %s,
                gender = %s, address = %s, phone_number = %s,
                email = %s, blood_group = %s, emergency_contact = %s,
                room_number = %s, is_admitted = %s
            WHERE patient_id = %s
        """, (data['first_name'], data['last_name'], data['date_of_birth'],
              data['gender'], data['address'], data['phone_number'],
              data.get('email'), data.get('blood_group'), data['emergency_contact'],
              data.get('room_number'), 'is_admitted' in data, patient_id))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_doctor/<int:doctor_id>')
def get_doctor(doctor_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM Doctors WHERE doctor_id = %s", (doctor_id,))
        doctor = cursor.fetchone()
        cursor.close()
        conn.close()
        return jsonify(doctor)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/update_doctor/<int:doctor_id>', methods=['POST'])
def update_doctor(doctor_id):
    try:
        data = request.form
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE Doctors 
            SET first_name = %s, last_name = %s, license_number = %s,
                staff_id = %s, department_id = %s, specialization = %s,
                phone_number = %s, email = %s, qualification = %s,
                experience_years = %s
            WHERE doctor_id = %s
        """, (data['first_name'], data['last_name'], data['license_number'],
              data['staff_id'], data['department_id'], data['specialization'],
              data['phone_number'], data.get('email'), data['qualification'],
              data['experience_years'], doctor_id))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_appointment/<int:appointment_id>')
def get_appointment(appointment_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT a.*, p.first_name as patient_first_name, p.last_name as patient_last_name,
                   d.first_name as doctor_first_name, d.last_name as doctor_last_name
            FROM Appointments a
            JOIN Patients p ON a.patient_id = p.patient_id
            JOIN Doctors d ON a.doctor_id = d.doctor_id
            WHERE a.appointment_id = %s
        """, (appointment_id,))
        appointment = cursor.fetchone()
        cursor.close()
        conn.close()
        return jsonify(appointment)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/update_appointment/<int:appointment_id>', methods=['POST'])
def update_appointment(appointment_id):
    try:
        data = request.form
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE Appointments 
            SET patient_id = %s, doctor_id = %s,
                appointment_date = %s, appointment_time = %s,
                status = %s
            WHERE appointment_id = %s
        """, (data['patient_id'], data['doctor_id'],
              data['appointment_date'], data['appointment_time'],
              data['status'], appointment_id))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/staff')
def staff():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM staff")
        staff_members = cursor.fetchall()
        cursor.close()
        conn.close()
        return render_template('staff.html', staff_members=staff_members)
    except Exception as e:
        return str(e), 500

@app.route('/add_staff', methods=['POST'])
def add_staff():
    try:
        data = request.get_json()
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO staff (first_name, last_name, role, hire_date, phone_number, email)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (data['first_name'], data['last_name'], data['role'], data['hire_date'], 
              data['phone_number'], data['email']))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/delete_staff/<int:staff_id>', methods=['DELETE'])
def delete_staff(staff_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM staff WHERE staff_id = %s", (staff_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

if __name__ == '__main__':
    app.run(debug=True, port=5002) 
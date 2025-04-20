document.addEventListener('DOMContentLoaded', function() {
    // Load initial data
    loadPatients();
    loadStaff();
    loadDepartments();
    loadRooms();
    loadAppointments();
    loadTests();
    loadDropdownData();

    // Add event listeners for forms
    document.getElementById('patientForm').addEventListener('submit', handlePatientSubmit);
    document.getElementById('staffForm').addEventListener('submit', handleStaffSubmit);
    document.getElementById('departmentForm').addEventListener('submit', handleDepartmentSubmit);
    document.getElementById('roomForm').addEventListener('submit', handleRoomSubmit);
    document.getElementById('appointmentForm').addEventListener('submit', handleAppointmentSubmit);
    document.getElementById('testForm').addEventListener('submit', handleTestSubmit);

    // Add event listener for room type change
    document.getElementById('room_type').addEventListener('change', handleRoomTypeChange);
});

function loadDropdownData() {
    // Load doctors for department head selection
    fetch('/get_doctors')
        .then(response => response.json())
        .then(doctors => {
            const headDoctorSelect = document.getElementById('head_doctor');
            const doctorIdSelect = document.getElementById('doctor_id');
            
            doctors.forEach(doctor => {
                const option = new Option(doctor.NAME, doctor.id_STAFF);
                headDoctorSelect.add(option.cloneNode(true));
                doctorIdSelect.add(option);
            });
        })
        .catch(error => console.error('Error loading doctors:', error));

    // Load departments for staff and room assignment
    fetch('/get_departments')
        .then(response => response.json())
        .then(departments => {
            const departmentSelect = document.getElementById('department_id');
            const roomDeptSelect = document.getElementById('room_dept');
            
            departments.forEach(dept => {
                const option = new Option(dept.DEPARTMENT_NAME, dept.DEPTID);
                departmentSelect.add(option.cloneNode(true));
                roomDeptSelect.add(option);
            });
        })
        .catch(error => console.error('Error loading departments:', error));

    // Load receptionists for appointment creation
    fetch('/get_receptionists')
        .then(response => response.json())
        .then(receptionists => {
            const receptionistSelect = document.getElementById('receptionist_id');
            receptionists.forEach(receptionist => {
                receptionistSelect.add(new Option(receptionist.NAME, receptionist.id_STAFF));
            });
        })
        .catch(error => console.error('Error loading receptionists:', error));

    // Load patients for appointment creation
    fetch('/get_patients')
        .then(response => response.json())
        .then(patients => {
            const patientSelect = document.getElementById('patient_id_appointment');
            patients.forEach(patient => {
                patientSelect.add(new Option(patient.NAME, patient.PATIENT_ID));
            });
        })
        .catch(error => console.error('Error loading patients:', error));
}

function loadPatients() {
    fetch('/get_patients')
        .then(response => response.json())
        .then(data => {
            const tbody = document.querySelector('#patientsTable tbody');
            tbody.innerHTML = '';
            
            data.forEach(patient => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${patient.PATIENT_ID}</td>
                    <td>${patient.NAME}</td>
                    <td>${new Date(patient.DOB).toLocaleDateString()}</td>
                    <td>${patient.GENDER}</td>
                    <td>${patient.CONTACT_NO}</td>
                `;
                tbody.appendChild(row);
            });
        })
        .catch(error => console.error('Error loading patients:', error));
}

function loadStaff() {
    fetch('/get_staff')
        .then(response => response.json())
        .then(data => {
            const tbody = document.querySelector('#staffTable tbody');
            tbody.innerHTML = '';
            
            data.forEach(staff => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${staff.id_STAFF}</td>
                    <td>${staff.NAME}</td>
                    <td>${staff.Role}</td>
                    <td>${staff.DEPARTMENT_NAME}</td>
                `;
                tbody.appendChild(row);
            });
        })
        .catch(error => console.error('Error loading staff:', error));
}

function loadDepartments() {
    fetch('/get_departments')
        .then(response => response.json())
        .then(data => {
            const tbody = document.querySelector('#departmentsTable tbody');
            tbody.innerHTML = '';
            
            data.forEach(dept => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${dept.DEPTID}</td>
                    <td>${dept.DEPARTMENT_NAME}</td>
                    <td>${dept.Location}</td>
                    <td>${dept.doctor_name}</td>
                `;
                tbody.appendChild(row);
            });
        })
        .catch(error => console.error('Error loading departments:', error));
}

function loadRooms() {
    fetch('/get_rooms')
        .then(response => response.json())
        .then(rooms => {
            const tbody = document.querySelector('#roomsTable tbody');
            tbody.innerHTML = '';
            rooms.forEach(room => {
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td>${room.room_id}</td>
                    <td>${room.room_number}</td>
                    <td>${room.room_type}</td>
                    <td>${room.status}</td>
                    <td>
                        <button class="btn btn-danger btn-sm" onclick="deleteRoom(${room.room_id})">Delete</button>
                    </td>
                `;
                tbody.appendChild(tr);
            });
        })
        .catch(error => console.error('Error loading rooms:', error));
}

function loadAppointments() {
    fetch('/get_appointments')
        .then(response => response.json())
        .then(data => {
            const tbody = document.querySelector('#appointmentsTable tbody');
            tbody.innerHTML = '';
            
            data.forEach(appointment => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${appointment.APPOINTENT_ID}</td>
                    <td>${appointment.patient_name}</td>
                    <td>${appointment.doctor_name}</td>
                    <td>${new Date(appointment.DATE).toLocaleString()}</td>
                `;
                tbody.appendChild(row);
            });
        })
        .catch(error => console.error('Error loading appointments:', error));
}

function loadTests() {
    fetch('/get_tests')
        .then(response => response.json())
        .then(data => {
            const tbody = document.querySelector('#testsTable tbody');
            tbody.innerHTML = '';
            
            data.forEach(test => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${test.TestID}</td>
                    <td>${test.Test_name}</td>
                    <td>${new Date(test.Date).toLocaleDateString()}</td>
                    <td>${test.Cost}</td>
                `;
                tbody.appendChild(row);
            });
        })
        .catch(error => console.error('Error loading tests:', error));
}

function handlePatientSubmit(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    
    fetch('/add_patient', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showAlert('Patient added successfully!', 'success');
            loadPatients();
            event.target.reset();
        } else {
            showAlert(data.message, 'danger');
        }
    })
    .catch(error => {
        showAlert('Error adding patient: ' + error, 'danger');
    });
}

function handleStaffSubmit(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    
    fetch('/add_staff', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showAlert('Staff added successfully!', 'success');
            loadStaff();
            loadDropdownData();
            event.target.reset();
        } else {
            showAlert(data.message, 'danger');
        }
    })
    .catch(error => {
        showAlert('Error adding staff: ' + error, 'danger');
    });
}

function handleDepartmentSubmit(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    
    fetch('/add_department', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showAlert('Department added successfully!', 'success');
            loadDepartments();
            loadDropdownData();
            event.target.reset();
        } else {
            showAlert(data.message, 'danger');
        }
    })
    .catch(error => {
        showAlert('Error adding department: ' + error, 'danger');
    });
}

function handleRoomSubmit(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    
    fetch('/add_room', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showAlert('Room added successfully!', 'success');
            loadRooms();
            event.target.reset();
        } else {
            showAlert(data.message, 'danger');
        }
    })
    .catch(error => {
        showAlert('Error adding room: ' + error, 'danger');
    });
}

function handleAppointmentSubmit(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    
    fetch('/schedule_appointment', {
        method: 'POST',
        body: formData
    })
    .then(response => {
        if (!response.ok) {
            return response.json().then(data => {
                throw new Error(data.error || 'Error scheduling appointment');
            });
        }
        return response;
    })
    .then(() => {
        showAlert('Appointment scheduled successfully!', 'success');
        loadAppointments();
        event.target.reset();
    })
    .catch(error => {
        showAlert(error.message, 'danger');
    });
}

function handleTestSubmit(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    
    fetch('/add_test', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showAlert('Test added successfully!', 'success');
            loadTests();
            event.target.reset();
        } else {
            showAlert(data.message, 'danger');
        }
    })
    .catch(error => {
        showAlert('Error adding test: ' + error, 'danger');
    });
}

function handleRoomTypeChange(event) {
    const roomType = event.target.value;
    const additionalFields = document.getElementById('roomAdditionalFields');
    
    if (additionalFields) {
        additionalFields.remove();
    }
    
    let html = '<div id="roomAdditionalFields">';
    
    switch (roomType) {
        case 'consultation':
            html += `
                <div class="mb-3">
                    <label class="form-label">Equipment Count</label>
                    <input type="number" class="form-control" name="equipment_count" required>
                </div>
            `;
            break;
        case 'patient':
            html += `
                <div class="mb-3">
                    <label class="form-label">Bed Count</label>
                    <input type="number" class="form-control" name="bed_count" required>
                </div>
                <div class="mb-3">
                    <label class="form-label">Room Type</label>
                    <select class="form-control" name="patient_room_type" required>
                        <option value="Ward">Ward</option>
                        <option value="Private">Private</option>
                        <option value="ICU">ICU</option>
                    </select>
                </div>
            `;
            break;
        case 'waiting':
            html += `
                <div class="mb-3">
                    <label class="form-label">Seating Capacity</label>
                    <input type="number" class="form-control" name="seating_capacity" required>
                </div>
            `;
            break;
    }
    
    html += '</div>';
    event.target.parentNode.insertAdjacentHTML('afterend', html);
}

function showAlert(message, type) {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `;
    
    const container = document.querySelector('.container');
    container.insertBefore(alertDiv, container.firstChild);
    
    setTimeout(() => {
        alertDiv.remove();
    }, 5000);
}

function deletePatient(patientId) {
    if (confirm('Are you sure you want to delete this patient?')) {
        fetch(`/delete_patient/${patientId}`, {
            method: 'DELETE',
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                loadPatients();
            } else {
                alert('Error deleting patient: ' + data.error);
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error deleting patient');
        });
    }
}

function deleteDoctor(doctorId) {
    if (confirm('Are you sure you want to delete this doctor?')) {
        fetch(`/delete_doctor/${doctorId}`, {
            method: 'DELETE',
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                loadDoctors();
            } else {
                alert('Error deleting doctor: ' + data.error);
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error deleting doctor');
        });
    }
}

function deleteRoom(roomId) {
    if (confirm('Are you sure you want to delete this room?')) {
        fetch(`/delete_room/${roomId}`, {
            method: 'DELETE',
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                loadRooms();
            } else {
                alert('Error deleting room: ' + data.error);
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error deleting room');
        });
    }
}

// Edit Patient
function editPatient(id) {
    // Get patient data
    fetch(`/get_patient/${id}`)
        .then(response => response.json())
        .then(patient => {
            // Create a modal for editing
            const modal = document.createElement('div');
            modal.className = 'modal fade';
            modal.id = 'editPatientModal';
            modal.innerHTML = `
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">Edit Patient</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <form id="editPatientForm">
                            <div class="modal-body">
                                <div class="mb-3">
                                    <label class="form-label">First Name</label>
                                    <input type="text" class="form-control" name="first_name" value="${patient.first_name}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Last Name</label>
                                    <input type="text" class="form-control" name="last_name" value="${patient.last_name}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Date of Birth</label>
                                    <input type="date" class="form-control" name="date_of_birth" value="${patient.date_of_birth}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Gender</label>
                                    <select class="form-control" name="gender" required>
                                        <option value="Male" ${patient.gender === 'Male' ? 'selected' : ''}>Male</option>
                                        <option value="Female" ${patient.gender === 'Female' ? 'selected' : ''}>Female</option>
                                        <option value="Other" ${patient.gender === 'Other' ? 'selected' : ''}>Other</option>
                                    </select>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Address</label>
                                    <textarea class="form-control" name="address">${patient.address || ''}</textarea>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Phone Number</label>
                                    <input type="text" class="form-control" name="phone_number" value="${patient.phone_number}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Email</label>
                                    <input type="email" class="form-control" name="email" value="${patient.email || ''}">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Blood Group</label>
                                    <input type="text" class="form-control" name="blood_group" value="${patient.blood_group || ''}">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Emergency Contact</label>
                                    <input type="text" class="form-control" name="emergency_contact" value="${patient.emergency_contact}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Room Number</label>
                                    <input type="text" class="form-control" name="room_number" value="${patient.room_number || ''}">
                                </div>
                                <div class="mb-3">
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" name="is_admitted" ${patient.is_admitted ? 'checked' : ''}>
                                        <label class="form-check-label">Is Admitted</label>
                                    </div>
                                </div>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                                <button type="submit" class="btn btn-primary">Save Changes</button>
                            </div>
                        </form>
                    </div>
                </div>
            `;
            document.body.appendChild(modal);
            
            // Show the modal
            const modalInstance = new bootstrap.Modal(modal);
            modalInstance.show();
            
            // Handle form submission
            document.getElementById('editPatientForm').addEventListener('submit', function(e) {
                e.preventDefault();
                const formData = new FormData(this);
                
                fetch(`/update_patient/${id}`, {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        modalInstance.hide();
                        window.location.reload();
                    } else {
                        alert('Error updating patient: ' + data.error);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error updating patient');
                });
            });
            
            // Clean up modal when hidden
            modal.addEventListener('hidden.bs.modal', function() {
                document.body.removeChild(modal);
            });
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error loading patient data');
        });
}

// Edit Doctor
function editDoctor(id) {
    fetch(`/get_doctor/${id}`)
        .then(response => response.json())
        .then(doctor => {
            const modal = document.createElement('div');
            modal.className = 'modal fade';
            modal.id = 'editDoctorModal';
            modal.innerHTML = `
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">Edit Doctor</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <form id="editDoctorForm">
                            <div class="modal-body">
                                <div class="mb-3">
                                    <label class="form-label">First Name</label>
                                    <input type="text" class="form-control" name="first_name" value="${doctor.first_name}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Last Name</label>
                                    <input type="text" class="form-control" name="last_name" value="${doctor.last_name}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">License Number</label>
                                    <input type="text" class="form-control" name="license_number" value="${doctor.license_number}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Staff ID</label>
                                    <input type="text" class="form-control" name="staff_id" value="${doctor.staff_id}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Department</label>
                                    <select class="form-control" name="department_id" required>
                                        ${departments.map(dept => `
                                            <option value="${dept.department_id}" ${dept.department_id === doctor.department_id ? 'selected' : ''}>
                                                ${dept.department_name}
                                            </option>
                                        `).join('')}
                                    </select>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Specialization</label>
                                    <input type="text" class="form-control" name="specialization" value="${doctor.specialization}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Phone Number</label>
                                    <input type="text" class="form-control" name="phone_number" value="${doctor.phone_number}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Email</label>
                                    <input type="email" class="form-control" name="email" value="${doctor.email || ''}">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Qualification</label>
                                    <input type="text" class="form-control" name="qualification" value="${doctor.qualification}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Experience (Years)</label>
                                    <input type="number" class="form-control" name="experience_years" value="${doctor.experience_years}" required>
                                </div>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                                <button type="submit" class="btn btn-primary">Save Changes</button>
                            </div>
                        </form>
                    </div>
                </div>
            `;
            document.body.appendChild(modal);
            
            const modalInstance = new bootstrap.Modal(modal);
            modalInstance.show();
            
            document.getElementById('editDoctorForm').addEventListener('submit', function(e) {
                e.preventDefault();
                const formData = new FormData(this);
                
                fetch(`/update_doctor/${id}`, {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        modalInstance.hide();
                        window.location.reload();
                    } else {
                        alert('Error updating doctor: ' + data.error);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error updating doctor');
                });
            });
            
            modal.addEventListener('hidden.bs.modal', function() {
                document.body.removeChild(modal);
            });
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error loading doctor data');
        });
}

// Edit Appointment
function editAppointment(id) {
    fetch(`/get_appointment/${id}`)
        .then(response => response.json())
        .then(appointment => {
            const modal = document.createElement('div');
            modal.className = 'modal fade';
            modal.id = 'editAppointmentModal';
            modal.innerHTML = `
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">Edit Appointment</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <form id="editAppointmentForm">
                            <div class="modal-body">
                                <div class="mb-3">
                                    <label class="form-label">Patient</label>
                                    <select class="form-control" name="patient_id" required>
                                        ${patients.map(patient => `
                                            <option value="${patient.patient_id}" ${patient.patient_id === appointment.patient_id ? 'selected' : ''}>
                                                ${patient.first_name} ${patient.last_name}
                                            </option>
                                        `).join('')}
                                    </select>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Doctor</label>
                                    <select class="form-control" name="doctor_id" required>
                                        ${doctors.map(doctor => `
                                            <option value="${doctor.doctor_id}" ${doctor.doctor_id === appointment.doctor_id ? 'selected' : ''}>
                                                Dr. ${doctor.first_name} ${doctor.last_name}
                                            </option>
                                        `).join('')}
                                    </select>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Date</label>
                                    <input type="date" class="form-control" name="appointment_date" value="${appointment.appointment_date}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Time</label>
                                    <input type="time" class="form-control" name="appointment_time" value="${appointment.appointment_time}" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Status</label>
                                    <select class="form-control" name="status" required>
                                        <option value="Scheduled" ${appointment.status === 'Scheduled' ? 'selected' : ''}>Scheduled</option>
                                        <option value="Completed" ${appointment.status === 'Completed' ? 'selected' : ''}>Completed</option>
                                        <option value="Cancelled" ${appointment.status === 'Cancelled' ? 'selected' : ''}>Cancelled</option>
                                    </select>
                                </div>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                                <button type="submit" class="btn btn-primary">Save Changes</button>
                            </div>
                        </form>
                    </div>
                </div>
            `;
            document.body.appendChild(modal);
            
            const modalInstance = new bootstrap.Modal(modal);
            modalInstance.show();
            
            document.getElementById('editAppointmentForm').addEventListener('submit', function(e) {
                e.preventDefault();
                const formData = new FormData(this);
                
                fetch(`/update_appointment/${id}`, {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        modalInstance.hide();
                        window.location.reload();
                    } else {
                        alert('Error updating appointment: ' + data.error);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error updating appointment');
                });
            });
            
            modal.addEventListener('hidden.bs.modal', function() {
                document.body.removeChild(modal);
            });
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error loading appointment data');
        });
} 
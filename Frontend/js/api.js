/* HealPoint live API client. Run the Java backend on localhost:8080. */
const API_BASE_URL = window.HEALPOINT_API_BASE_URL || "http://localhost:8080/api";
async function apiRequest(method, endpoint, data) {
  const options={method,headers:{"Content-Type":"application/json","Accept":"application/json"}};
  if(data!==undefined) options.body=JSON.stringify(data);
  let response;
  try { response=await fetch(`${API_BASE_URL}${endpoint}`,options); }
  catch(e){ throw new Error("Backend unreachable. Start the HealPoint Java API on http://localhost:8080 and check MySQL settings."); }
  const payload=await response.json().catch(()=>({success:false,message:"Invalid API response"}));
  if(!response.ok) throw new Error(payload.message || `${method} ${endpoint} failed (${response.status})`);
  return payload;
}
const apiGet=(e)=>apiRequest("GET",e), apiPost=(e,d)=>apiRequest("POST",e,d), apiPut=(e,d)=>apiRequest("PUT",e,d), apiDelete=(e)=>apiRequest("DELETE",e);
const DoctorService={async list(){return (await apiGet("/doctors")).map(x=>({...x,id:String(x.id),status:x.active?"Active":"Inactive"}));},create:d=>apiPost("/doctors",d),update:(id,d)=>apiPut(`/doctors/${id}`,d),remove:id=>apiDelete(`/doctors/${id}`)};
const PatientService={async list(){return (await apiGet("/patients")).map(x=>({...x,id:String(x.id),status:"Active"}));},create:d=>apiPost("/patients",d),update:(id,d)=>apiPut(`/patients/${id}`,d),remove:id=>apiDelete(`/patients/${id}`)};
const AppointmentService={async list(){return (await apiGet("/appointments")).map(x=>({...x,id:String(x.id),date:x.appointmentDate,patientName:x.patient,doctorName:x.doctor}));},book:d=>apiPost("/appointments",d),updateStatus:(id,status)=>apiPut(`/appointments/${id}/status`,{status}),cancel:id=>apiPut(`/appointments/${id}/cancel`,{})};
const VisitService={list:()=>apiGet("/visits"),create:d=>apiPost("/visits",d)};
const PrescriptionService={list:()=>apiGet("/prescriptions"),create:d=>apiPost("/prescriptions",d)};
const BillingService={list:()=>apiGet("/bills"),create:d=>apiPost("/bills",d)};
const AuditService={list:()=>apiGet("/audit-logs")};
const AuthService={login:(email,password,role)=>apiPost("/auth/login",{email,password,role}),register:d=>apiPost("/auth/register",d)};

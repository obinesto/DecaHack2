import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import HomePage from "./components/Landing/HomePage";
import Auth from "./components/Authentication/Auth";
import PageNotFound from "./components/NotFound"
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

export default function App() {
  const notify = (message, notificationType) =>
    toast(message, {
      position: "top-right",
      autoClose: 3000,
      hideProgressBar: false,
      closeOnClick: true,
      pauseOnHover: true,
      draggable: true,
      theme: "dark",
      type: notificationType,
      style: {
        fontFamily: "'Poppins', sans-serif",
        borderRadius: "8px",
      },
    });

  return (
    <Router>
      <Routes>
        <Route path="*" element={<PageNotFound />} />
        <Route path="/" element={<HomePage />} />
        <Route path="/login" element={<Auth notify={notify} />} />
        <Route path="/register" element={<Auth notify={notify} />} />
      </Routes>
      <ToastContainer />
    </Router>
  );
}

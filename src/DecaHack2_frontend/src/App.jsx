import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import HomePage from "./components/Pages/HomePage";
// import Auth from "./components/Authentication/Auth";

export default function App() {
  return (
    <Router>
      <Routes>
        <Route path="*" element={<HomePage />} />
        <Route path="/" element={<HomePage />} />
        {/* <Route path="/login" element={<Auth />} /> */}
        {/* <Route path="/register" element={<Auth />} /> */}
      </Routes>
    </Router>
  );
}

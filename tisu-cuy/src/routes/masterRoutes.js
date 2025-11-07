import express from "express";
import {
  getPegawai,
  getLokasi,
  getDispenser,
  getLogin,
  getAdmin,
  createAdmin
} from "../controllers/masterController.js";

const router = express.Router();

router.get("/pegawai", getPegawai);
router.get("/lokasi", getLokasi);
router.get("/dispenser", getDispenser);
router.get("/login", getLogin);
router.get("/admin", getAdmin);
router.post("/admin", createAdmin);

export default router;
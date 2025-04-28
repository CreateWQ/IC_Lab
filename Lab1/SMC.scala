package SMC

import chisel3._
import circt.stage.ChiselStage
import chisel3.util._

class SMC extends Module {

    val INPUT_NUM = 6

    val W = IO(Input(Vec(INPUT_NUM, UInt(3.W))))
    val V_GS = IO(Input(Vec(INPUT_NUM, UInt(3.W))))
    val V_DS = IO(Input(Vec(INPUT_NUM, UInt(3.W))))
    val mode = IO(Input(UInt(2.W)))

    val out_n = IO(Output(UInt(10.W)))

    // Checking MOSFET is in Triode or Saturation region
    val is_Tri = Wire(Vec(INPUT_NUM, Bool()))
    for (i <- 0 until INPUT_NUM) {
        when (V_GS(i) - 1.U > V_DS(i)) {
            is_Tri(i) := true.B
        }.otherwise {
            is_Tri(i) := false.B
        }
    }
    // The current formula in triode region:
    //      ID = W * (2 * (V_GS - 1) * V_DS - V_DS ^ 2) 
    // The factors in triode region, as follow: 
    //      A: V_DS
    //      B: W 
    //      C: 2 * V_GS - V_DS - 2
    val ID_tri_A = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val ID_tri_B = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val ID_tri_C = Wire(Vec(INPUT_NUM, UInt(4.W)))
    // The current formula in saturation region:
    //      ID = W * (V_GS - 1) ^ 2 / 3
    // The current factors in saturation region, as follows: 
    //      A: W
    //      B: V_GS - 1 
    //      C: V_GS - 1
    val ID_sat_A = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val ID_sat_B = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val ID_sat_C = Wire(Vec(INPUT_NUM, UInt(3.W)))
    // The transconductance formula in triode region: 
    //      gm = 2 * W * V_DS / 3
    // The transconductance factors in triode region, as follow: 
    //      A: 2
    //      B: W 
    //      C: V_DS
    val gm_tri_A = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val gm_tri_B = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val gm_tri_C = Wire(Vec(INPUT_NUM, UInt(3.W)))
    // The transconductance formula in saturation region: 
    //      gm = 2 * W * (V_GS - 1) / 3
    // The transconductance factors in saturation region, as follow: 
    //      A: 2
    //      B: W 
    //      C: V_GS - 1
    val gm_sat_A = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val gm_sat_B = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val gm_sat_C = Wire(Vec(INPUT_NUM, UInt(3.W)))
    

    for (i <- 0 until INPUT_NUM) {
        ID_tri_A(i) := V_DS(i)
        ID_tri_B(i) := W(i)
        ID_tri_C(i) := 2.U * V_GS(i) - V_DS(i) -2.U

        gm_tri_A(i) := 2.U
        gm_tri_B(i) := W(i)
        gm_tri_C(i) := V_DS(i)

        ID_sat_A(i) := W(i)
        ID_sat_B(i) := V_GS(i) - 1.U
        ID_sat_C(i) := V_GS(i) - 1.U

        gm_sat_A(i) := 2.U
        gm_sat_B(i) := W(i)
        gm_sat_C(i) := V_GS(i) - 1.U
    }

    val ID_A = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val ID_B = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val ID_C = Wire(Vec(INPUT_NUM, UInt(4.W)))

    val gm_A = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val gm_B = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val gm_C = Wire(Vec(INPUT_NUM, UInt(3.W)))


    for (i <- 0 until INPUT_NUM) {
        when (is_Tri(i)) {
            ID_A(i) := ID_tri_A(i)
            ID_B(i) := ID_tri_B(i)
            ID_C(i) := ID_tri_C(i)

            gm_A(i) := gm_tri_A(i)
            gm_B(i) := gm_tri_B(i)
            gm_C(i) := gm_tri_C(i)
        }.otherwise {
            ID_A(i) := ID_sat_A(i)
            ID_B(i) := ID_sat_B(i)
            ID_C(i) := ID_sat_C(i)

            gm_A(i) := gm_sat_A(i)
            gm_B(i) := gm_sat_B(i)
            gm_C(i) := gm_sat_C(i)
        }

    }

    val A = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val B = Wire(Vec(INPUT_NUM, UInt(3.W)))
    val C = Wire(Vec(INPUT_NUM, UInt(4.W)))

    for (i <- 0 until INPUT_NUM) {

        when (mode(0)) {
            A(i) := ID_A(i)
            B(i) := ID_B(i)
            C(i) := ID_C(i)
        }.otherwise {
            A(i) := gm_A(i)
            B(i) := gm_B(i)
            C(i) := gm_C(i)
        }

    }

    val cal_out = Wire(Vec(INPUT_NUM, UInt(10.W)))

    for (i <- 0 until INPUT_NUM) {
        cal_out(i) := (A(i) * B(i) * C(i)) / 3.U
    }

    val sort = Module(new Sorting)

    val n = Wire(Vec(INPUT_NUM, UInt(10.W)))

    sort.in := cal_out
    n := sort.out

    val n1 = Wire(Vec(3, UInt(10.W)))

    when (mode(1)) {
        n1(0) := n(0)
        n1(1) := n(1)
        n1(2) := n(2)
    } .otherwise {
        n1(0) := n(3)
        n1(1) := n(4)
        n1(2) := n(5)
    }

    val out_1 = Wire(UInt(10.W))
    val out_2 = Wire(UInt(10.W))
    val out_3 = Wire(UInt(10.W))

    when (mode(0)) {
        out_1 := (n1(0) << 1.U) + n1(0)
        out_2 := (n1(1) << 2.U)
        out_3 := (n1(2) << 2.U) + n1(2)
    } .otherwise {
        out_1 := n1(0)
        out_2 := n1(1)
        out_3 := n1(2)
    }

    out_n := out_1 + out_2 + out_3

}


object SMCMain extends App {

    ChiselStage.emitSystemVerilogFile(
        new SMC, 
        Array("--target-dir", "generated"),
        firtoolOpts = Array("-disable-all-randomization", "-strip-debug-info")
    )

}

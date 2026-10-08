/* =====================================================================
   DEMO TRANH CHAP - CUA SO 1 (SSMS Query Window so 1)       [Nguyễn Đăng Khoa - 24110255]
   Mo file 02_TranhChap_Setup.sql chay truoc. Sau do:
     - Mo HAI cua so truy van rieng (New Query) cho cung CSDL QL_TTNgoaiNgu.
     - Cua so 1: file nay.  Cua so 2: file 02b_TranhChap_CuaSo2.sql.
     - Chay PHAN 1 o cua so 1, trong vong 10 giay chay PHAN 1 o cua so 2.
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO

/* ===================== PHAN 1: KHONG KHOA (sai) =====================
   Ca hai cua so thay "1/2 -> con cho" va deu ghi -> lop co 3 hoc vien (vuot 2).        */
EXEC dbo.SP_DEMO_DangKy_KhongKhoa @MaDK = 'DKC01', @MaHV = 'HV002', @MaLop = 'LCC001', @DelayGiay = 10;
GO

/* >>> Sau khi PHAN 1 xong o ca hai cua so: chay 03_TranhChap_KiemTra_DonDep.sql muc A (kiem tra)
       va muc B (dat lai ve 1 hoc vien) roi moi chay PHAN 2.  <<< */


/* ===================== PHAN 2: CO KHOA (dung) - SP_DangKy_VaTaoHoaDon =====================
   Giu giao dich mo 15 giay SAU khi dang ky de cua so 2 phai doi (bi chan tren dong LOP).
   Chay PHAN 2 o cua so 1, trong 15 giay chay PHAN 2 o cua so 2 -> cua so 2 bi doi,
   sau khi cua so 1 COMMIT thi cua so 2 thay lop da day va nhan loi 52029.                */
BEGIN TRANSACTION;
    DECLARE @dk VARCHAR(8), @hd VARCHAR(8);
    EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV002', @MaLop = 'LCC001', @NgayDangKy = NULL,
                                   @SoTienThuNgay = NULL, @MaDK = @dk OUTPUT, @MaHD = @hd OUTPUT;
    SELECT N'Cua so 1 dang ky thanh cong' AS KetQua, @dk AS MaDK, @hd AS MaHD;
    WAITFOR DELAY '00:00:15';
COMMIT TRANSACTION;
GO

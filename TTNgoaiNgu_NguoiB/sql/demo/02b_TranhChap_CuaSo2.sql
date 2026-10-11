/* =====================================================================
   DEMO TRANH CHAP - CUA SO 2 (SSMS Query Window so 2)       [Nguyễn Đăng Khoa - 24110255]
   Chay SAU cua so 1 trong vong vai giay (xem huong dan o 02a_TranhChap_CuaSo1.sql).
   ===================================================================== */
USE QL_TTNgoaiNgu;
GO

/* ===================== PHAN 1: KHONG KHOA (sai) ===================== */
EXEC dbo.SP_DEMO_DangKy_KhongKhoa @MaDK = 'DKC02', @MaHV = 'HV003', @MaLop = 'LCC001', @DelayGiay = 10;
GO


/* ===================== PHAN 2: CO KHOA (dung) =====================
   Cua so nay se bi DOI (ban se thay "Executing query..." dai vai giay) vi cua so 1 dang giu
   khoa UPDLOCK tren dong LOP LCC001. Khi cua so 1 COMMIT, thu tuc tiep tuc, dem lai si so = 2
   va nem loi 52029 "Lop ... da du si so (2/2)".                                              */
BEGIN TRY
    BEGIN TRANSACTION;
        DECLARE @dk VARCHAR(8), @hd VARCHAR(8);
        EXEC dbo.SP_DangKy_VaTaoHoaDon @MaHV = 'HV003', @MaLop = 'LCC001', @NgayDangKy = NULL,
                                       @SoTienThuNgay = NULL, @MaDK = @dk OUTPUT, @MaHD = @hd OUTPUT;
        SELECT N'Cua so 2 dang ky thanh cong' AS KetQua, @dk AS MaDK, @hd AS MaHD;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT N'Cua so 2 BI TU CHOI dung nhu mong doi' AS KetQua, ERROR_NUMBER() AS MaLoi, ERROR_MESSAGE() AS ThongBao;
END CATCH;
GO

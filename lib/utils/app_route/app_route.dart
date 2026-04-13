class AppRoute {
  // ===== USER =====
  static const splash = '/';
  static const userLogin = '/login'; // 사용자 로그인
  static const userRegister = '/register'; // 사용자 회원가입

  // ===== ADMIN =====
  static const adminLogin = '/admin_login'; // 관리자 로그인
  static const adminMainPage = '/admin_mainpage'; // 관리자 대시보드

  static const adminParkingList = '/admin_parking_list'; // 관리자 대시보드
  static const adminParkingView = '/admin_parking_view'; // 주차장 상세
  static const adminParkingUpdate = '/admin_parking_update'; // 주차장 수정
  static const adminParkingAdd = '/admin_parking_add'; // 주차장 추가

  // static const adminPerformanceCreate = '/admin_performance_create';
  static const adminAskingList = '/admin_asking_list'; // 문의글 리스트
  static const adminAskingView = '/admin_asking_view'; // 문의글 보기
  static const adminAskingResponse = '/admin_asking_response'; // 문의글 답변
  static const adminReservationList = '/admin_reservation_list'; // 예약 리스트 보기
  static const adminReservationView =
      '/admin_reservation_view'; // 예약 보기 및 허용, 거부 선택

  static const adminFacilityList = '/admin_facility_list'; // 시설 리스트
  static const adminFacilityView = '/admin_facility_view'; // 시설 상세
  static const adminFacilityUpdate = '/admin_facility_update'; // 시설 수정
  static const adminFacilityAdd = '/admin_facility_add'; // 시설 추가
}

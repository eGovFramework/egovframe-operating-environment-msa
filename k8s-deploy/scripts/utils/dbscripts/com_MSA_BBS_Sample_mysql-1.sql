use com;

UPDATE com.comtecopseq
SET NEXT_ID=101
WHERE TABLE_NAME='BBS_ID';


INSERT INTO com.comtnbbsmaster
(BBS_ID, BBS_NM, BBS_INTRCN, BBS_TY_CODE, REPLY_POSBL_AT, FILE_ATCH_POSBL_AT, ATCH_POSBL_FILE_NUMBER, ATCH_POSBL_FILE_SIZE, USE_AT, TMPLAT_ID, CMMNTY_ID, FRST_REGISTER_ID, FRST_REGIST_PNTTM, LAST_UPDUSR_ID, LAST_UPDT_PNTTM, BLOG_ID, BLOG_AT)
VALUES('BBSMSTR_000000000071lCjooWeRfs', 'test001', 'test001-111111', 'BBST01', 'Y', 'Y', 1, NULL, 'Y', '', '', 'USRCNFRM_00000000001', '2025-02-12 11:20:45.0', NULL, NULL, '', 'N');

INSERT INTO com.comtnbbsmaster
(BBS_ID, BBS_NM, BBS_INTRCN, BBS_TY_CODE, REPLY_POSBL_AT, FILE_ATCH_POSBL_AT, ATCH_POSBL_FILE_NUMBER, ATCH_POSBL_FILE_SIZE, USE_AT, TMPLAT_ID, CMMNTY_ID, FRST_REGISTER_ID, FRST_REGIST_PNTTM, LAST_UPDUSR_ID, LAST_UPDT_PNTTM, BLOG_ID, BLOG_AT)
VALUES('BBSMSTR_000000000086LabXlUEdSn', '전체옵션 활성화 게시판', '게시판의 모든 옵션 활성화
- 게시판 유형 : 통합게시판
- 답글 가능
- 파일첨부 가능 : 최대 3개
- 댓글 가능', 'BBST01', 'Y', 'Y', 3, NULL, 'Y', NULL, NULL, 'USRCNFRM_00000000001', '2025-03-26 09:55:48.0', 'USRCNFRM_00000000001', '2025-03-26 09:55:48.0', NULL, NULL);


INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(121, 'BBSMSTR_000000000071lCjooWeRfs', 1, 'SQL 처리가 오래걸릴때 timeout 설정 방법', '<p>&lt;em&gt;Q&lt;/em&gt;현재 jpql이나 native query등으로 sql을 처리할시 DB에 데이터량이 너무 많아서 처리 시간이 오래 걸리는데, timeout이 강제적으로 30초로 지정이 되어있습니다.<br />
application.yml 등에 timeout 설정을 해줘도 강제적으로 30초인데 혹시 다른 곳에서 설정을 해야랄까요?</p>', 'N', 0, 0, 121, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:14:48.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(122, 'BBSMSTR_000000000071lCjooWeRfs', 1, 'DB 접속 &#40;Connection&#41; 후 Close&#40;&#41; 미처리 발생 가능성 여부', '<p>&nbsp;</p>

<p>안녕하세요.<br />
<br />
DB 접속&#40;Connection&#41; 후 Close&#40;&#41; 처리가 되지 않아,<br />
실제 DB 연결은 되지 않았지만 AP&#40;Weblogic&#41; 단에서 DB Connection Pool 연결되어 있는 것처럼 프로세스를 유지하고 있어<br />
Connection leak이 발생하여 다수의 thread가 대기 상태&#40;TIMED_WATING&#41;가 되어<br />
Weblogic AP서버를 강제 재기동하는 것으로 조치한 사례가 발생하였습니다.<br />
<br />
어플리케이션 단&#40;자바프로그램&#41; 에서 close처리를 manual하게 하는 것은 아니고 &#40;close&#40;&#41;처리 넣으면 UnsupportedOperationException: Manual close is not allowed over a Spring managed SqlSession&#41; 발생&#41; 프레임워크의 기능에서 자동처리하고 있는 것으로 보이는데<br />
해당 프레임워크 버전의 기능에서 close&#40;&#41; 처리가 미비한게 있어서 버전 업그레이드를 해야한다든지,<br />
다른 조치 방안이 있다든지 조언해주실 만한 내용이 있을지요?<br />
확인 부탁드립니다.<br />
<br />
감사합니다.</p>', 'N', 0, 0, 122, 1, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:14:59.0', 'USRCNFRM_00000000000', '2025-02-26 13:15:01.0', 'USRCNFRM_00000000000', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(123, 'BBSMSTR_000000000071lCjooWeRfs', 1, 'DB접속정보 암호화 중 오류 재문의&#40;crypto 간소화 서비스&#41;', '<p>안녕하세요.<br />
<br />
crypto 간소화 서비스로<br />
globals.properties 파일에 암호화 후 DB접속을 진행하고 있습니다.<br />
<br />
https://www.egovframe.go.kr/wiki/doku.php?id=egovframework:rte4.2:fdl:crypto<br />
위 위키대로 해서 잘됩니다.<br />
<br />
다만,<br />
govEnvCryptoService.getPassword&#40;&#41;<br />
이 실행시에는 다른 결과 값이 나옵니다.<br />
확인해보니,<br />
<br />
EgovEnvCryptoServiceImpl 의<br />
<br />
/**<br />
* Crypto 알고리즘 키에 대한 setter<br />
* @param cyptoAlgorithmKey 알고리즘키<br />
*/<br />
public void setCyptoAlgorithmKey&#40;String cyptoAlgorithmKey&#41; {<br />
this.cyptoAlgorithmKey = cyptoAlgorithmKey;<br />
}<br />
<br />
에<br />
<br />
cyptoAlgorithmKey에 &quot;testKey&quot; 값이 들어갑니다.<br />
<br />
모든 설정에 cyptoAlgorithmKey 값은 &quot;egovframe&quot;로 설정했습니다.<br />
&#40;프로젝트내 모든 파일에서 &quot;testKey&quot; 문자열은 찾을수 없음&#41;<br />
<br />
도대체 cyptoAlgorithmKey에 &quot;testKey&quot; 값은 어디서 오는건가요 ?<br />
아니면, 별도 cyptoAlgorithmKey을 설정해야 하나요 ?<br />
<br />
감사합니다.</p>', 'N', 0, 0, 123, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:15:25.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(124, 'BBSMSTR_000000000071lCjooWeRfs', 1, '다중 datasource 구성 후 간헐적 에러 발생', '<p>안녕하세요<br />
전자정부프레임워크 3.6 버전으로<br />
mysql을 master , slave 로 다중 datasource 로 사용하고있습니다.<br />
<br />
현재 쿼리 호출시 dao에서 super.setSuperSqlMapClient&#40;&#41; 을 datasource를 master 또는 slave로 사용하게 되어있습니다.<br />
<br />
위와 같이 쿼리 마다 master , salve 로 datasource를 지정하여 사용하고 있는데 접속자 수가 많아지는 시간때에 가끔씩 master로 설정되어있음에도 불구하고 slave로 붙는 현상이 나오고 있는데 이를 해결할수있는 방법이 있을까요?<br />
<br />
public void insertLoginHistory&#40;MBPUserVO vo&#41; {<br />
SqlMapClient sqlMapClient SelectSqlMap.selectSqlMap&#40;SqlMapClientConstant .ACTIVE_SOLMAP_CLIENT&#41;:<br />
super : sstSuperSglMapclient &#40;sgihapmlisnt&#41;:<br />
insert &#40;&quot;MBPUserDAO.insertLoginHistoty&quot;, vo&#41;;<br />
}</p>', 'N', 0, 0, 124, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:15:35.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(125, 'BBSMSTR_000000000071lCjooWeRfs', 1, '엑셀 다운로드 시 파일명 변경 방법', '<p>&lt;em&gt;Q&lt;/em&gt;엑셀다운로드 시 기존에는 response.setHeader&#40;&quot;Content-Disposition&quot;, &quot;attachment; filename=\\&quot;&quot; + fileName + &quot;\\&quot;&quot;&#41;; 이렇게 헤더에 Content-Disposition 값을 주면 해당 파일명으로 다운로드가 되었는데<br />
4.2에서는 가이드대로 엑셀다운로드 참고하여 개발 해보니 &#40;xlsx버전&#41;AbstractPOIExcelView 를 써서 그런건지 엑셀 다운로드 파일명이 Content-Disposition 값을 줘도 자바파일명으로 다운로드가 되는데 이 부분 어떻게 해야 파일명을 변경할 수 있을까요?<br />
지금은 엑셀 다운로드 시 자바파일명.xlsx 이렇게 다운로드 되고 있습</p>', 'N', 0, 0, 125, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:15:46.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(126, 'BBSMSTR_000000000071lCjooWeRfs', 1, '공통컴포넌트에 지원하는 기능이 없을경우 어떻게 해야하나요?', '<p>딥러닝등 AI관련한 기능들에 대해서는 공통컴포넌트로 제공하는 것 같아 보이지 않는데 플랫폼을 전자정부표준프레임워크를 사용하고, 파이썬으로 AI기능을 수행하는 API 서버를 만들어서 개발해도 되나요?</p>', 'N', 0, 0, 126, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:16:00.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(127, 'BBSMSTR_000000000071lCjooWeRfs', 1, '전자정부 배치 관련 문의', '<p>현재 전자정부배치&#40;bopr&#41;을 구동하여 기존 자체 배치 관리 서비스를 대체 진행중에 있습니다.<br />
<br />
웹페이지 구동 및, ftp 설정 등 마무리 이후, 배치 등록 후 배치 정상 작동 확인하려고하나, 기존 배치파일을 어떤식으로 등록해야할지 감이 잡히지 않아 질문드립니다.<br />
<br />
bopr을 통해 구축된 사이트에 배포&#40;배치심의관리, 배치배포관리를 통해&#41;하기 위한 배치 프로젝트 개발 방법 문의드립니다.<br />
<br />
간단한 db to db 테이블 복사 작업 등의 배치 업무를 수행하기 위한 배치 프로젝트를 등록하는 것이 목표입니다.<br />
<br />
배치 메뉴얼 &#40;실행환경_실습교재&#40;배치처리&#41;&#41;를 확인하여 개발해보아도 무엇을 어떻게 등록해야하는지 잘 모르겠습니다.<br />
<br />
추가적으로 작성한 배치파일의 문제점이 있는지 확인 부탁드립니다.</p>', 'N', 0, 0, 127, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:16:15.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(128, 'BBSMSTR_000000000071lCjooWeRfs', 1, '전자정부 사용 여부, 호환성 관련 문의드립니다', '<p>안녕하세요.<br />
<br />
<br />
1. 가이드 상 표준 프레임워크 적용 여부를 만족하는 소스가 공통 컴포넌트는 사용하지 않았을 경우, 해당 소스가 전자정부가 적용되었다고 볼 수 있나요?<br />
<br />
2. 공통 컴포넌트의 사용 여부, 개수가 &#39;전자정부 호환성확인&#39;에 영향을 주는 내용인가요?<br />
<br />
3. QueryDSL 과 같은 MyBatis/JPA 이외의 기술 사용은 &#39;전자정부 적용 여부&#39;, &#39;호환성확인&#39; 에는 영향을 주지 않는 요소인가요?<br />
<br />
4. 전자정부 사용 여부를 판단하는 기준 중 감리 등에서 지침하는 기준이 있을까요?<br />
<br />
<br />
확인 부탁드립니다!</p>', 'N', 0, 0, 128, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:16:29.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(129, 'BBSMSTR_000000000071lCjooWeRfs', 1, '새로고침 시 메인페이지로 이동', '<p>로그인을 하게되면 왼쪽에 메뉴, 메인페이지가 뜨게 됩니다.<br />
예를들어<br />
a 메뉴를 클릭하면 a 페이지 출력됩니다.<br />
새로고침을 누르면 a 페이지가 유지가 되어야하는데 자꾸 메인페이지로 넘어가네요<br />
<br />
왜 이런걸까요...? 그리고 어떻게 해결해야 새로고침&#40;F5&#41;를 눌렀을 때 메인페이지가 아닌 현재 페이지를 유지할 수 있을까요?</p>', 'N', 0, 0, 129, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:16:47.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(130, 'BBSMSTR_000000000071lCjooWeRfs', 1, 'servlet 질문있습니다.', '<p>&nbsp;</p>

<p>안녕하세요.<br />
servlet 관련 하여 질문 있습니다.<br />
<br />
현재 프레임워크 3.1 버전에 servlet 2.5 사용중인데<br />
servlet 버전을 3.0 까지 올릴려면 프레임워크버전은 몇까지 올려야 하나요 ?<br />
3.1 버전에서는 불가능한지요 ?</p>

<p>&nbsp;</p>', 'N', 0, 0, 130, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:16:57.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(131, 'BBSMSTR_000000000071lCjooWeRfs', 1, '설정정보 차단 방법', '<p>&nbsp;</p>

<p>http://localhost:8888/user-service/dev<br />
설정정보를 호출하게되면 관련정보가 노출이 되는데,<br />
기본적으로 id와 passwd는 암호화를 했지만,<br />
이 설정 호출을 아예 외부에서 접근이 안되게 하는 방법이 있을까요 ?<br />
일반적으로 저부분을 어떻게 관리는하는지 궁금합니다.</p>', 'N', 0, 0, 131, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:17:12.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(132, 'BBSMSTR_000000000071lCjooWeRfs', 1, 'example에 있는 config 마이그레이션', '<p>&nbsp;</p>

<p>eGovFrame Boot Web Project를 처음 생성 할 때 Generate Example 하여 생성된<br />
config의 설정을 application.properties로 마이그레이션 하여도 전자정부 프레임워크로 인정되는건가요?</p>', 'N', 0, 0, 132, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:17:25.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(133, 'BBSMSTR_000000000071lCjooWeRfs', 1, 'pmd reports 생성 안됨', '<p>전자정부프레임워크 4.2를 테스트하고 있습니다<br />
<br />
샘플 코드로 만들어서 현재 환경을 테스트 중인데,<br />
pmd에서 코드 검사는 잘 되는데 report가 생성되지 않습니다.<br />
<br />
룰셋은 전자정부에서 제공하는 4.2 기준으로 적용 완료하였고,<br />
설정에서 pmd 보고서 확장자도 지정했습니다.<br />
<br />
검사를 하지 않은 상태에서 Generate Reports를 했을 때는 결과값이 없는 빈 파일들이 잘 만들어지는데,<br />
코드 검사 후 Generate Reports를 클릭하면 아무 반응도 없고 파일도 만들어지지 않더라구요.<br />
<br />
해당 내용에 대해서 이전 질문중에도 reports가 생성되지 않는다는 질문글이 있던데,<br />
&#40;https://www.egovframe.go.kr/home/qainfo/qainfoRead.do?pagerOffset=0&amp;searchKey=&amp;searchValue=&amp;menuNo=69&amp;qaId=QA_00000000000020749&#41;<br />
<br />
1. 해당부분 해결이 되었는지<br />
2. 해결되었다면 어떻게 해야 하는지<br />
<br />
안내 부탁드립니다.<br />
<br />
감사합니다.</p>', 'N', 0, 0, 133, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', NULL, NULL, NULL, NULL, '2025-02-26 13:17:41.0', 'USRCNFRM_00000000000', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(134, 'BBSMSTR_000000000071lCjooWeRfs', 1, 'gpki 연동시 decode에러가 발생됩니다', '<p>gpki 인증서 로그인을 개발중 해당부분에서 decode에러가 발생되어 진행이 안되는 상황입니다.<br />
<br />
gpkisecureweb.uiapi.MakeSignData&#40; sData, null, function&#40;code, message&#41;{<br />
if&#40;code == 0&#41;{<br />
<br />
var oSignedData = message.encMsg;<br />
<br />
var oSignContentInfo = mGenInterface.MakeSignContentInfo&#40;gpkijs.base64.decode&#40;oSignedData&#41;, gpkijs.base64.decode&#40;message.vidRandom&#41;&#41;;<br />
<br />
<br />
{func: &#39;ds.base64.decode&#39;, name: &#39;DecodeError&#39;, code: 2129920, message: &#39;It does not allow the use GPKIJS. &#40;5&#41;&#39;}</p>', 'N', 0, 0, 134, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000001', '일반회원', '', NULL, NULL, NULL, NULL, '2025-02-26 13:18:06.0', 'USRCNFRM_00000000001', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(135, 'BBSMSTR_000000000071lCjooWeRfs', 1, '파일첨부시 파일명 생성 규칙 문의', '<p>안녕하세요<br />
현재 파일 첨부를 할 경우 첨부파일 ID를 생성시<br />
fileIdGnrService.getNextStringId&#40;&#41;를 사용합니다.<br />
해당 기능이 처음엔 시퀀스의 NEXTVAL형식이라고 생각했는데<br />
최근 각 다른 기능에서 동타이밍에 파일이 생성 되었는데 같은 첨부파일 ID를 가지고 있어 한쪽만 파일이 생성되어있는 경우가 확인되어서, 혹시 fileIdGnrService.getNextStringId&#40;&#41;의 생성 방식이 시퀀스의 NEXTVAL형식이 아닌 MAX+1과 같은 방식이어서 동타이밍 호출시 같은 파일ID가 생성 될수있는지 궁금합니다.</p>', 'N', 0, 0, 135, 0, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000001', '일반회원', '', NULL, NULL, NULL, NULL, '2025-02-26 13:18:19.0', 'USRCNFRM_00000000001', NULL, NULL, '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(136, 'BBSMSTR_000000000071lCjooWeRfs', 1, '개발자 교육', '<p>안녕하세요<br />
24년 6차 개발자 교육 신청 기간, 교육 기간이 궁금합니다.<br />
감사합니다</p>', 'N', 0, 0, 136, 3, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000001', '일반회원', '', NULL, NULL, NULL, NULL, '2025-02-26 13:18:28.0', 'USRCNFRM_00000000001', '2025-03-10 14:06:12.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(141, 'BBSMSTR_000000000071lCjooWeRfs', 1, '문의 드립니다', '<p>취약점 제보합니다 글 수정 좀 봐 주세요</p>', 'N', 0, 0, 141, 4, 'Y', '2025-02-26', '2025-02-28', 'USRCNFRM_00000000000', '테스트1', '', '', 'N', 'N', 'N', '2025-02-27 09:19:50.0', 'USRCNFRM_00000000000', '2025-03-05 11:05:16.0', '', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(151, 'BBSMSTR_000000000071lCjooWeRfs', 1, '문의 드립니다33333', '<p>취약점 제보합니다33333</p>', 'N', 0, 0, 151, 3, 'N', '2025-02-27', '2025-02-28', 'USRCNFRM_00000000000', '테스트1', '', '', 'N', 'N', 'N', '2025-02-27 09:27:47.0', 'USRCNFRM_00000000000', '2025-02-27 09:55:39.0', '', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(171, 'BBSMSTR_000000000071lCjooWeRfs', 1, '긴급사항', '<p>오류가 확인되므로 &nbsp;test 수정 테스트 요청합니다.</p>', 'N', 0, 0, 171, 11, 'Y', '2025-02-27', '2025-02-28', 'USRCNFRM_00000000000', '테스트1', '', '', 'N', 'N', 'N', '2025-02-27 10:18:22.0', 'USRCNFRM_00000000000', '2025-03-04 16:51:02.0', 'USRCNFRM_00000000000', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(202, 'BBSMSTR_000000000071lCjooWeRfs', 1, '테스트 게시물입니다', '<p>테스트합니다 수정 테스트</p>', 'N', 0, 0, 202, 3, 'N', '2025-03-04', '2025-03-08', 'USRCNFRM_00000000000', '테스트1', '', '', 'N', 'N', 'N', '2025-03-04 16:07:09.0', 'USRCNFRM_00000000000', '2025-03-04 16:07:27.0', '', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(211, 'BBSMSTR_000000000071lCjooWeRfs', 1, '3월 5일 테스트 사항입니다', '<p>오늘자 테스트입니다</p>', 'N', 0, 0, 211, 2, 'Y', '2025-03-05', '2025-03-08', 'USRCNFRM_00000000000', '테스트1', '', '', 'N', 'N', 'N', '2025-03-05 13:04:17.0', 'USRCNFRM_00000000000', NULL, '', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(221, 'BBSMSTR_000000000071lCjooWeRfs', 1, '글 작성 테스트', '<p>신규 작성입니다</p>', 'N', 0, 0, 221, 1, 'Y', '2025-03-05', '2025-03-08', 'USRCNFRM_00000000000', '테스트1', '', '', 'N', 'N', 'N', '2025-03-05 13:27:34.0', 'USRCNFRM_00000000000', '2025-03-06 14:54:08.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(223, 'BBSMSTR_000000000071lCjooWeRfs', 1, '신규 문의입니다', '<p>실행 시 어려움이 있어 질문 드립니다.</p><p>어떻게 해야 할까요?</p>', 'N', 0, 0, 223, 3, 'N', '2025-03-05', '2025-03-08', 'USRCNFRM_00000000000', '테스트1', '', '', 'N', 'N', 'N', '2025-03-05 13:32:59.0', 'USRCNFRM_00000000000', '2025-03-05 13:33:18.0', '', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(225, 'BBSMSTR_000000000071lCjooWeRfs', 1, '오늘의 연동 테스트', '<p>정상적으로 될까요?</p><p>궁금합니다</p>', 'N', 0, 0, 225, 3, 'N', '2025-03-05', '2025-03-08', 'USRCNFRM_00000000000', '테스트1', '', '', 'N', 'N', 'N', '2025-03-05 13:37:04.0', 'USRCNFRM_00000000000', '2025-03-05 13:37:19.0', '', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(227, 'BBSMSTR_000000000071lCjooWeRfs', 1, '수정 테스트 111222', '<p>수정 테스트 111222</p>', 'N', 0, 0, 227, 3, 'Y', '2025-03-05', '2025-03-08', 'USRCNFRM_00000000000', '테스트1', '', '', 'N', 'N', 'N', '2025-03-05 13:55:51.0', 'USRCNFRM_00000000000', '2025-03-06 14:54:06.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(229, 'BBSMSTR_000000000071lCjooWeRfs', 1, '수정테스트 333444', '<p>수정테스트 333444</p>', 'N', 0, 0, 229, 3, 'Y', '2025-03-05', '2025-03-08', 'USRCNFRM_00000000000', '테스트1', '', '', 'N', 'N', 'N', '2025-03-05 13:56:22.0', 'USRCNFRM_00000000000', '2025-03-06 14:54:01.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(231, 'BBSMSTR_000000000071lCjooWeRfs', 1, '파일 등록 및 다운로드 테스트', '<p>파일 등록 및 다운로드 테스트</p>', 'N', 0, 0, 231, 2, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000001', '일반회원', '', 'FILE_000000000000341', NULL, NULL, NULL, '2025-03-06 14:54:38.0', 'USRCNFRM_00000000001', '2025-03-11 10:57:40.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(241, 'BBSMSTR_000000000071lCjooWeRfs', 1, '공통컴포넌트 4.3.0 254종 Version 4.3.0 배포 공지', '&lt;p&gt;실행환경 4.3.0 업그레이드 반영&lt;br&gt;공통컴포넌트 연계모듈 3종 추가 적용 (OpenSearch 검색엔진, 국가보훈증, 재외국민신원확인증)&lt;br&gt;공통컴포넌트 26종 KRDS(Korea Design System) 및 MSA 적용&lt;br&gt;51명의 개발자 컨트리뷰션 534 건 반영&lt;br&gt;KISA, NSR(국가보안기술연구소)의 보안 점검 결과 반영을 통한 시큐어 코딩&lt;/p&gt;', 'N', 0, 0, 241, 4, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, NULL, '2025-03-10 14:43:59.0', 'USRCNFRM_00000000001', '2025-03-11 17:21:32.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(251, 'BBSMSTR_000000000071lCjooWeRfs', 1, '3월 11일자 1차 테스트 입니다', '&lt;p&gt;테스트 내용 상세입니다&lt;/p&gt;', 'N', 0, 0, 251, 2, 'Y', '2025-03-11', '2025-03-15', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, NULL, '2025-03-11 10:28:40.0', 'USRCNFRM_00000000001', '2025-03-11 10:34:52.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(252, 'BBSMSTR_000000000071lCjooWeRfs', 1, '3월 11일자 2차 테스트 입니다', '&lt;p&gt;2차 테스트 내용입니다.&lt;/p&gt;', 'N', 0, 0, 252, 4, 'Y', '2025-03-11', '2025-03-15', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, NULL, '2025-03-11 10:36:04.0', 'USRCNFRM_00000000001', '2025-03-11 10:54:41.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(261, 'BBSMSTR_000000000071lCjooWeRfs', 1, ' 3월 11일자 3차 테스트 입니다', '&lt;p&gt;3차 테스트 내용입니다&lt;/p&gt;', 'N', 0, 0, 261, 5, 'N', '2025-03-11', '2025-03-15', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, NULL, '2025-03-11 10:55:06.0', 'USRCNFRM_00000000001', '2025-03-11 17:22:15.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(271, 'BBSMSTR_000000000071lCjooWeRfs', 1, '3월 11일자 4차 테스트 입니다', '&lt;p&gt;4차 테스트 내용입니다&lt;/p&gt;', 'N', 0, 0, 271, 15, 'Y', '2025-03-11', '2025-03-15', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, NULL, '2025-03-11 15:09:10.0', 'USRCNFRM_00000000001', '2025-03-11 19:32:11.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(281, 'BBSMSTR_000000000071lCjooWeRfs', 1, '3월 12일 문의 드립니다', '&lt;p&gt;egov web project 생성시, 기본 구조만 생성되게 할 수 있나요?&lt;br&gt;&lt;br&gt;generate sample source 체크 해서 프로젝트를 생성하면, 샘플 소스 자체가 생성되어서 사용하지 않습니다.&lt;br&gt;generate sample source 체크 하지 않고 프로젝트를 생성하면, 아무것도 생성되지 않아서 globals.properties 파일도 없는 상태 입니다.&lt;br&gt;여기서 common component 추가해서 ''공통''만 체크해서 추가해도 너무 많은 소스와 ddl, dml 내용들도 추가됩니다.&lt;br&gt;&lt;br&gt;egov web project 생성하고, 최소한의 기본 구조와 globals.properties 생성된 상태로 시작할 수 있는 방법이 있을까요?&lt;/p&gt;', 'N', 0, 0, 281, 4, 'Y', '2025-03-12', '2025-03-15', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, NULL, '2025-03-12 14:25:35.0', 'USRCNFRM_00000000001', '2025-03-19 16:27:27.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(301, 'BBSMSTR_000000000071lCjooWeRfs', 1, '공통 컴포넌트 관련 문의 드립니다', '&lt;p&gt;msa 기반 공통 컴포넌트에서 각 모듈의 역할을 알고 싶습니다&lt;/p&gt;', 'N', 0, 0, 301, 17, 'Y', '2025-03-19', '2025-03-22', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, NULL, '2025-03-19 16:44:12.0', 'USRCNFRM_00000000001', '2025-03-27 13:40:16.0', '', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(311, 'BBSMSTR_000000000086LabXlUEdSn', 1, '게시글 등록 테스트', '&lt;p&gt;&lt;strong&gt;이미지 삽입 가능&lt;/strong&gt;&lt;/p&gt;&lt;p&gt;&amp;nbsp;&lt;/p&gt;&lt;p&gt;&lt;img src=&quot;/cop/brd/ckeditor/72sYzyY7Lq45JKH7Z3DFpj9x9SZRb5AIi-Ik7UMNR7NKSNIQZb4Kplx59pQnigAXp4o0EVPqh8qDbxsbZusTTA.png&quot; width=&quot;249&quot; height=&quot;39&quot;&gt;&amp;nbsp;&lt;/p&gt;&lt;p&gt;&amp;nbsp;&lt;/p&gt;&lt;ol&gt;&lt;li&gt;목록 1&lt;/li&gt;&lt;li&gt;목록 2&lt;/li&gt;&lt;li&gt;목록3&lt;ol&gt;&lt;li&gt;서브 목록 1&lt;/li&gt;&lt;li&gt;서브 목록 2&lt;ol&gt;&lt;li&gt;3depth&lt;/li&gt;&lt;/ol&gt;&lt;/li&gt;&lt;/ol&gt;&lt;/li&gt;&lt;/ol&gt;&lt;p&gt;&amp;nbsp;&lt;/p&gt;&lt;p&gt;&lt;a target=&quot;_blank&quot; rel=&quot;noopener noreferrer&quot; href=&quot;https://www.egovframe.go.kr/home/main.do&quot;&gt;https://www.egovframe.go.kr/home/main.do&lt;/a&gt;&lt;br&gt;링크 연결 확인&lt;/p&gt;&lt;p&gt;&amp;nbsp;&lt;/p&gt;&lt;p&gt;표 생성 확인&lt;/p&gt;&lt;figure class=&quot;table&quot;&gt;&lt;table&gt;&lt;tbody&gt;&lt;tr&gt;&lt;td&gt;테이블 생성&lt;/td&gt;&lt;td&gt;제목1&lt;/td&gt;&lt;td&gt;제목2&lt;/td&gt;&lt;td&gt;제목3&lt;/td&gt;&lt;/tr&gt;&lt;tr&gt;&lt;td&gt;데이터&lt;/td&gt;&lt;td&gt;데이터1&lt;/td&gt;&lt;td&gt;데이터2&lt;/td&gt;&lt;td&gt;데이터3&lt;/td&gt;&lt;/tr&gt;&lt;/tbody&gt;&lt;/table&gt;&lt;/figure&gt;&lt;p&gt;&amp;nbsp;&lt;/p&gt;', 'N', 0, 0, 311, 7, 'Y', '2025-03-26', '2025-03-29', 'USRCNFRM_00000000001', '일반회원', NULL, 'FILE_000000000000351', NULL, NULL, NULL, '2025-03-26 10:00:59.0', 'USRCNFRM_00000000001', '2025-03-26 16:32:42.0', 'USRCNFRM_00000000000', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(312, 'BBSMSTR_000000000086LabXlUEdSn', 1, '공지사항입니다.', '&lt;p&gt;공지사항 게시글 등록&lt;/p&gt;', 'N', 0, 0, 312, 17, 'Y', '2025-03-26', '2025-03-26', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, 'Y', NULL, NULL, '2025-03-26 10:02:13.0', 'USRCNFRM_00000000001', '2025-03-27 17:22:30.0', 'USRCNFRM_00000000000', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(313, 'BBSMSTR_000000000086LabXlUEdSn', 1, '비밀글 입니다.', '&lt;p&gt;비밀글로 작성되어 작성한 본인만 열람 가능&lt;/p&gt;', 'N', 0, 0, 313, 2, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, 'Y', '2025-03-26 10:06:27.0', 'USRCNFRM_00000000001', '2025-03-26 16:33:09.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(314, 'BBSMSTR_000000000086LabXlUEdSn', 1, '익명으로 작성된 게시글입니다.', '&lt;p&gt;익명등록 선택 시 작성자 아이디가 &lsquo;익명&rsquo;으로 변경&lt;/p&gt;', 'N', 0, 0, 314, 4, 'Y', '1900-01-01', '9999-12-31', 'annoymous', '익명', NULL, NULL, NULL, NULL, NULL, '2025-03-26 10:07:14.0', 'annoymous', '2025-04-09 14:22:57.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(315, 'BBSMSTR_000000000086LabXlUEdSn', 1, '제목을 강조하여 표시한 게시글', '&lt;p&gt;제목 진하게 선택 시 제목이 Bold 형태로 표시&lt;/p&gt;', 'N', 0, 0, 315, 7, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, 'Y', NULL, '2025-03-26 10:07:40.0', 'USRCNFRM_00000000001', '2025-03-27 18:07:36.0', 'USRCNFRM_00000000000', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(316, 'BBSMSTR_000000000086LabXlUEdSn', 1, '게시글 등록 테스트의 답글입니다.', '&lt;p&gt;&ldquo;게시글 등록 테스트&rdquo; 의 답글 게시글&lt;/p&gt;', 'N', 0, 0, 316, 2, 'N', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, NULL, '2025-03-26 10:16:41.0', 'USRCNFRM_00000000001', '2025-03-26 10:17:07.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(321, 'BBSMSTR_000000000086LabXlUEdSn', 2, '게시글 등록 테스트의 답글', '&lt;p&gt;게시글 등록 테스트의 답글 테스트&lt;/p&gt;', 'Y', 311, 1, 311, 2, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, NULL, '2025-03-26 11:06:12.0', 'USRCNFRM_00000000001', '2025-03-26 16:33:13.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(322, 'BBSMSTR_000000000086LabXlUEdSn', 3, '답글의 답글 테스트', '&lt;p&gt;답글의 답글 테스트&lt;/p&gt;', 'Y', 321, 2, 311, 1, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000001', '일반회원', NULL, NULL, NULL, NULL, NULL, '2025-03-26 11:06:25.0', 'USRCNFRM_00000000001', '2025-03-26 16:33:16.0', 'USRCNFRM_00000000001', '');
INSERT INTO com.comtnbbs
(NTT_ID, BBS_ID, NTT_NO, NTT_SJ, NTT_CN, ANSWER_AT, PARNTSCTT_NO, ANSWER_LC, SORT_ORDR, RDCNT, USE_AT, NTCE_BGNDE, NTCE_ENDDE, NTCR_ID, NTCR_NM, PASSWORD, ATCH_FILE_ID, NOTICE_AT, SJ_BOLD_AT, SECRET_AT, FRST_REGIST_PNTTM, FRST_REGISTER_ID, LAST_UPDT_PNTTM, LAST_UPDUSR_ID, BLOG_ID)
VALUES(331, 'BBSMSTR_000000000071lCjooWeRfs', 1, '데용량 파일 업로드 태스트', '<p>ㅌㅅㅌ</p>', 'N', 0, 0, 331, 6, 'Y', '1900-01-01', '9999-12-31', 'USRCNFRM_00000000000', '테스트1', '', 'FILE_000000000000391', NULL, NULL, NULL, '2025-03-27 14:04:08.0', 'USRCNFRM_00000000000', '2025-03-27 14:06:47.0', 'USRCNFRM_00000000000', '');


commit;
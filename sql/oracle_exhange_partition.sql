/**************************
  Код для Oracle
***************************/
DROP TABLE agrmnt;
DROP TABLE agrmnt_res;

CREATE TABLE agrmnt (id NUMBER GENERATED BY DEFAULT AS IDENTITY,
					 agrmnt varchar2(100),
					 period DATE,
				 	 agrmnt_sum NUMBER,
				 	 type_operation char(1),
				 	 load_date date DEFAULT sysdate,
				 	 type_dml char(1) DEFAULT 'I')
	   PARTITION BY RANGE (agrmnt) (PARTITION agrmnt_prt VALUES LESS THAN (MAXVALUE));
CREATE INDEX idx_agrmnt_01 ON agrmnt (agrmnt);

CREATE TABLE agrmnt_res FOR exchange WITH TABLE agrmnt;
 
 
-- Генерируем данные
BEGIN
 EXECUTE IMMEDIATE 'TRUNCATE TABLE agrmnt';
 -- Пишем начисления
 FOR agr IN (SELECT '001/01/'||dbms_random.string('U',9) agrmnt, round(dbms_random.value(1000,2000)) agrmnt_sum, 'A' type_operation FROM dual CONNECT BY LEVEL <= 1000)
 LOOP
  FOR pr IN (SELECT ADD_MONTHS(trunc(sysdate,'yyyy'),LEVEL-1) period FROM dual CONNECT BY 0+LEVEL < 121)
  LOOP
	INSERT INTO agrmnt (agrmnt, period, agrmnt_sum, type_operation) VALUES (agr.agrmnt, pr.period, agr.agrmnt_sum, agr.type_operation);  	
  END LOOP;
 END LOOP;
 
 -- Пишем оплаты, делаем так что может образоваться по итогу оплат либо перебор либо недобор
 FOR agr IN (SELECT agrmnt, period+dbms_random.value(1,20) period, round(dbms_random.value(agrmnt_sum-100,agrmnt_sum+100)) agrmnt_sum, 'P' type_operation  
  			   FROM agrmnt)
 LOOP
  INSERT INTO agrmnt (agrmnt, period, agrmnt_sum, type_operation) VALUES (agr.agrmnt, agr.period, agr.agrmnt_sum, agr.type_operation);  	
 END LOOP;
 COMMIT;
END;

SELECT 'agrmnt_res' table_name, count(*) FROM agrmnt_res
 UNION all
SELECT 'agrmnt' table_name, count(*) FROM agrmnt;

-- Меняем раздел
alter table agrmnt exchange partition agrmnt_prt with table agrmnt_res without validation update global indexes;

SELECT 'agrmnt_res' table_name, count(*) FROM agrmnt_res
 UNION all
SELECT 'agrmnt' table_name, count(*) FROM agrmnt;
BEGIN

-- Declare integer to keep track of incidents
DECLARE _missingadvanceinav INTEGER DEFAULT 0;


-- Declare logic variable
DECLARE _msisdn VARCHAR(20) DEFAULT 0;
DECLARE _advanceid BIGINT DEFAULT 0;
DECLARE _advancedate DATETIME DEFAULT '2020-01-12 00:00:00';

DECLARE _comment VARCHAR(250) DEFAULT 0;
DECLARE _apfamount DECIMAL(10,2) DEFAULT 0;
DECLARE _apfadvancecount INTEGER DEFAULT 0;
DECLARE _transactionid VARCHAR(100) DEFAULT 0;
-- Declare Cursor Handler (If true then exit loop)
DECLARE _cursor_finished INTEGER DEFAULT 0;
  
    
 

-- Declare cursor to retrieve issues
DECLARE advance_recon 
		CURSOR FOR 
					SELECT a1.apfmsisdn, a1.apfadvanceid, a1.eventdate, a1.apfamount, COMMENT, a1.advancecount, a1.transactionid
					from
					(					
						SELECT MIN(apf_advance_payment_feed.msisdn) AS apfmsisdn,
						MIN(eventdate) AS eventdate,
						MIN(apf_advance_payment_feed.advanceid) AS apfadvanceid,
						MIN(transactionid) AS transactionid,
						SUM(apf_advance_payment_feed.amount) AS apfamount,
						COUNT(apf_advance_payment_feed.advanceid) AS advancecount,
						MIN(subscriber.msisdn) AS financemsisdn,
						'Missing Advance in APF' AS COMMENT,
						SUM(charge.amount)
						FROM av_controller.apf_advance_payment_feed
						LEFT OUTER JOIN av_microservice_finance.charge
						ON charge.advanceid = apf_advance_payment_feed.advanceid
						AND transtypeid = 1
						LEFT JOIN av_microservice_finance.advance
						ON advance.advanceid = charge.advanceid
						AND advancedate >= _starttimestamp --  '2022-04-14 00:00:00'
						AND advancedate <= _endtimestamp -- '2022-04-14 23:59:59'
						AND statusid NOT IN (3)
						LEFT JOIN av_microservice_finance.subscriber
						ON advance.subscriberid = subscriber.subscriberid
						WHERE operationtype = 1
						AND eventdate >= _starttimestamp -- '2022-04-14 00:00:00'
						AND eventdate <= _endtimestamp -- '2022-04-14 23:59:59'
						AND subscriber.msisdn IS NULL
						GROUP BY apf_advance_payment_feed.advanceid
						) a1;

    
-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET _cursor_finished = 1;
        
        
-- DECLARE CURSOR to open
OPEN advance_recon;

advance_transaction: LOOP
-- Retrieve variables
							FETCH advance_recon INTO  _msisdn, _advanceid, _advancedate, _apfamount, _comment,
																					_apfadvancecount, _transactionid;

							-- Check if there are any records.
							IF _cursor_finished = 1 THEN 
								LEAVE advance_transaction;
							END IF;


						
								SET _comment = CONCAT('Missing Advance in finance for msisdn :', _msisdn, ' advanceid: ', _advanceid);
								
								INSERT INTO advance_log (runid, msisdn, advanceid, advancedate, amount, COMMENT) 
								VALUES (_runid, _msisdn, _advanceid, _advancedate, _apfamount, _comment);
								
								SET _missingadvanceinav = _missingadvanceinav + 1;
								
						
								
						
					


END LOOP advance_transaction;



CLOSE advance_recon;


-- Return summary 
	SET _result = CONCAT('Advances missing in Airvantage : ', _missingadvanceinav);


END
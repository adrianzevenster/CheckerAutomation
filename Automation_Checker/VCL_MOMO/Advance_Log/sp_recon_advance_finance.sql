SELECT a1.apfmsisdn, a1.apfadvanceid, a1.eventdate, apfamount, COMMENT, a1.advancecount, a1.transactionid
FROM
	(
		SELECT MIN(apf_advance_payment_feed.msisdn) AS apfmsisdn,
		MIN(eventdate) AS eventdate,
		MIN(apf_advance_payment_feed.advanceid) AS apfadvanceid,
		MIN(transactionid) AS transactionid,
		SUM(apf_advance_payment_feed.amount) AS apfamount,
		COUNT(apf_advance_payment_feed.advanceid) AS advancecount,
		MIN(subscriber.msisdn) AS financemsisdn,
		'Missing Advance in Finance' AS COMMENT,
		SUM(charge.amount)
		FROM av_controller.apf_advance_payment_feed
	LEFT OUTER JOIN av_microservice_finance.charge
	ON charge.advanceid = apf_advance_payment_feed.advanceid
		AND transtypeid = 1
	LEFT JOIN av_microservice_finance.advance
	ON advance.advanceid = charge.advanceid
		AND advancedate >= '2020-04-14 00:00:00'
		AND advancedate <= '2020-04-14 23:59:59'
		AND statusid NOT IN (3)
	LEFT JOIN av_microservice_finance.subscriber
	ON advance.subscriberid = subscriber.subscriberid
		WHERE operationtype = 1
-- 		AND vendorid = 1
		AND eventdate >= '2020-04-14 00:00:00'
		AND eventdate <= '2020-04-14 23:59:59'
		AND subscriber.msisdn IS NULL
	GROUP BY apf_advance_payment_feed.advanceid
) a1;
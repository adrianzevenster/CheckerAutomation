SELECT a1.msisdn, a1.advanceid, a1.advancedate, advanceamount, servicefeeamount,
					a1.apfamount, a1.apfadvancecount, a1.transactionid
					from
					(
					SELECT advance.advanceid,
					(subscriber.msisdn) AS msisdn,
					(advance.advancedate) AS advancedate,
					SUM(charge.advance_amt+charge.servicefee_amt) AS amount,
					SUM(charge.advance_amt) AS advanceamount,
					SUM(charge.servicefee_amt) AS servicefeeamount,
					SUM(charge.interest_amt) AS interestamount,
					(APF.apfmsisdn) AS apfmsisdn,
					(APF.eventdate) AS eventdate,
					(APF.apfadvanceid) AS apfadvanceid,
					(APF.apftransactionid) AS transactionid,
					SUM((APF.apfamount)) AS apfamount,
					SUM(APF.apfadvancecount) AS apfadvancecount
					FROM av_microservice_finance.advance advance
					LEFT JOIN av_microservice_finance.subscriber subscriber
					ON advance.subscriberid = subscriber.subscriberid
					LEFT JOIN		(SELECT
											advanceid,
											SUM(IF(transtypeid = 1, amount, 0)) AS advance_amt,
											SUM(IF(transtypeid = 2, amount, 0)) AS servicefee_amt,
											SUM(IF(transtypeid = 3, amount, 0)) AS interest_amt
											FROM av_microservice_finance.charge
											where transtypeid IN (1,2,3)
											AND chargedate >= '2020-04-14 00:00:00'
											AND chargedate <= '2020-04-14 23:59:59'
											GROUP BY advanceid) charge
					ON advance.advanceid=charge.advanceid
					LEFT JOIN	(SELECT msisdn AS apfmsisdn,
										advanceid AS apfadvanceid,
										MIN(eventdate) AS eventdate,
										MIN(transactionid) AS apftransactionid, SUM(amount) AS apfamount,
										COUNT(apf_advance_payment_feed.advanceid) AS apfadvancecount
										FROM
											av_controller.apf_advance_payment_feed
											WHERE operationtype = 1
											AND eventdate >= '2020-04-14 00:00:00'
											AND eventdate <=  '2020-04-14 23:59:59'
											GROUP BY  apfmsisdn, apfadvanceid
									) APF
					ON advance.advanceid=APF.apfadvanceid
					WHERE advance.statusid NOT IN (3)
					AND advance.advancedate >=  '2020-04-14 00:00:00' -- _starttimestamp
					AND advance.advancedate <= '2020-04-14 23:59:59'   -- _endtimestamp
					GROUP BY advance.advanceid, advancedate, msisdn, apfmsisdn, eventdate, apfadvanceid, transactionid) a1
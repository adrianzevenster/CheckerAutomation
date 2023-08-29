SELECT a1.msisdn, a1.advanceid, a1.advancedate, advanceamount, COMMENT, a1.totalrepayments, a1.maxpaymentdate, a1.statusid, a1.advance_comment
							from
							  (SELECT s.msisdn AS msisdn,
								advance.advanceid,
								SUM(c.advance_amt + c.servicefee_amt + c.interest) AS advanceamount,
								MIN(advance.statusid) AS statusid,
								MIN(advance.advancedate) AS advancedate,
								coalesce(SUM(p.deducted_advance_amt + p.deducted_servicefee_amt + p.interest), 0) AS totalrepayments,
								'Advance Status Check' as COMMENT,
								advance.comment AS advance_comment,
								MAX(p.paymentdate) AS maxpaymentdate

								FROM av_microservice_finance.advance AS advance
								LEFT JOIN av_microservice_finance.subscriber s
								ON advance.subscriberid = s.subscriberid
								LEFT JOIN
								(SELECT advanceid,
								SUM(IF(transtypeid = 1, amount, 0)) AS advance_amt,
								SUM(IF(transtypeid = 2, amount, 0)) AS servicefee_amt,
								SUM(IF(transtypeid = 3, amount, 0)) AS interest
								FROM av_microservice_finance.charge
								GROUP BY advanceid) AS c
								ON advance.advanceid = c.advanceid
								LEFT JOIN
								(SELECT advanceid,
									MAX(paymentdate) AS paymentdate,
									SUM(IF(transtypeid = 1, amount, 0)) AS deducted_advance_amt,
									SUM(IF(transtypeid = 2, amount, 0)) AS deducted_servicefee_amt,
									SUM(IF(transtypeid = 3, amount, 0)) AS interest
									FROM av_microservice_finance.payment
									GROUP BY advanceid)  p
									ON advance.advanceid = p.advanceid
								Where
								advance.advanceid in
								(SELECT advanceid
								FROM av_microservice_finance.payment
								WHERE paymentdate >= '2020-04-14 00:00:00'-- _starttimestamp -- '2020-06-12 00:00:00'
								AND paymentdate <=  '2020-04-14 23:59:59' -- _endtimestamp -- '2020-06-13 23:59:59'
								AND payment.statusid != '3')
								GROUP BY
								s.msisdn, advance.advanceid, advance_comment) a1
								;
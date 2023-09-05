SELECT p.msisdn,
       p.min_advanceid,
       p.advancedate,
       p.paymentdate,
       p.paid_total,
       p.paid_advance_amt,
       p.paid_servicefee_amt,
       p.paid_interest_amt,

       APF.amount,
       COALESCE(apf.apf_count, 0) AS apf_count,
       p.transactionid,
       p.subscriberid

FROM (SELECT payment.transactionid,

             advance.subscriberid,

             MIN(payment.advanceid)                              AS min_advanceid,

             MIN(subscriber.msisdn)                              AS msisdn,

             MIN(advance.advancedate)                            AS advancedate,

             MIN(payment.paymentdate)                            AS paymentdate,

             SUM(IF(payment.transtypeid = 1, payment.amount, 0)) AS paid_advance_amt,

             SUM(IF(payment.transtypeid = 2, payment.amount, 0)) AS paid_servicefee_amt,

             SUM(IF(payment.transtypeid = 3, payment.amount, 0)) AS paid_interest_amt,

             SUM(payment.amount)                                 AS paid_total

      FROM av_microservice_finance.payment AS payment

               LEFT JOIN av_microservice_finance.advance AS advance
                         ON payment.advanceid = advance.advanceid

               LEFT JOIN av_microservice_finance.subscriber AS subscriber
                         ON advance.subscriberid = subscriber.subscriberid

      Where transtypeid IN (1, 2, 3)

        AND paymentdate >= '2022-04-14 00:00:00'

        AND paymentdate <= '2023-04-14 23:59:59'

        AND payment.statusid <> 3

      GROUP BY payment.transactionid, advance.subscriberid) p

         LEFT JOIN

     (SELECT MIN(msisdn)          AS msisdn,

             MIN(advanceId)       AS advanceId,

             MIN(eventDate)       AS eventDate,

             SUM(amount)          AS amount,

             transactionId,

             COUNT(transactionId) AS apf_count

      FROM av_controller.apf_advance_payment_feed apf

      WHERE apf.operationType = 2

        AND apf.eventDate >= '2022-04-14 00:00:00'

        AND apf.eventDate <= '2023-04-14 23:59:59'

      GROUP BY transactionId) apf
     ON p.transactionid = apf.transactionid;

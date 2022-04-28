/*
select * from planning_charges2 where isBailQualified = 1


Jan 2018 -Jan 2020 ~ all charges 
Jan - July 2020 ~ isBailQualified = 1
July 2020 - Dec 2021 ~ isBailQualified = 1 + the added charges


how many arc were bail eligible by year
how many bail eligible arc has bail or remand requested
*/


--Jan 2018 -Jan 2020 ~ all charges 

IF OBJECT_ID('tempdb.dbo.#table', 'U') IS NOT NULL
DROP TABLE #table

/* 1. pull cases where bail or remand was requested */
SELECT DISTINCT 
	   fe.defendantID,
	   fe.nysid,
	   fe.name,
	   fe.docket,
	   fe.firstEvtId,
	   arcYear = YEAR(arcDate),
	   arcMonth = MONTH(arcDate),
	   pa.arcEventID,
	   pa.scrTopCat,
	   pa.scrTopChg,
	   pa.scrTopTxt,
	   pa.scrTopCMID,
	   scrTopVFO = 0,
	   BailRequested = CASE WHEN pa.BailReqAmt > 1 THEN BailReq ELSE 0 END, -- MSS: added here rather than later
	   BailSet = CASE WHEN pa.BailSetAmt > 1 THEN pa.BailSet ElSE 0 END,
	   RemandRequested = 0,
	   Remanded = CASE WHEN pa.ReleaseStatus = 'Remand' THEN 1 ELSE 0 END,
	   PolicyReason = 'Not available',
	   isBailEligible = 'Not available',
	   TimePeriod = 'Jan 2018 to Jan 2020'
INTO #table
FROM planning_arraignments2 pa
JOIN planning_fe2 fe on fe.defendantID = pa.defendantID
WHERE pa.arcDate BETWEEN '2018-01-01' AND '2019-12-31'
 AND fe.caseType <> 'Extradition'
	 

UPDATE #table
SET RemandRequested = 1
FROM #table t
WHERE EXISTS (SELECT 1
			FROM Evt
			JOIN EventLinkBailDetail ebd ON ebd.EventID = Evt.BailRequestEventId
			JOIN BailRequestTypeLU req ON req.BailRequestTypeId = ebd.BailRequestTypeID
			WHERE
				Evt.DefendantID = t.DefendantId 
			AND Evt.EventTypeID IN (2, 9, 165) --ecab, arc, youth part arc
			AND req.BailRequestType = 'Remand'
			)


UPDATE #table
SET RemandRequested = 1
FROM #table t
JOIN Planintdb.dbo.Planning_bail bail ON bail.DefendantID = t.DefendantID
WHERE
	BailReq_DMS LIKE '%remand%'
AND NOT EXISTS (SELECT 1
				FROM Evt 
				JOIN EventLinkBailDetail ebd ON ebd.EventID = Evt.BailRequestEventId
				JOIN BailRequestTypeLU brq ON brq.BailRequestTypeID = ebd.BailRequestTypeID
				WHERE
					Evt.DefendantID = t.DefendantId
				AND Evt.EventTypeID IN (2,9,165)
				)


UPDATE #table
SET scrTopVFO = 1 
FROM #table 
JOIN planning_charges2 pc on pc.chargemodificationid = #table.scrTopCMID
WHERE isVFO = 1 


UPDATE #table
SET scrTopCat = CASE WHEN scrTopCat = 'Felony' and scrTopVFO = 1 THEN 'VFO'
				     WHEN scrTopCat = 'Felony' and scrTopVfo = 0 THEN 'NVF'
					 ELSE scrTopCat END
FROM #table



---bail or remand requested between 2018 and 2020 Jan
;WITH totalArc AS (
 SELECT DISTINCT
        arcPeriod = 'Jan 2018 to Jan 2020',
        COUNT(DISTINCT pa.defendantID) AS TotalArc
   FROM planning_arraignments2 pa 
   JOIN planning_fe2 fe on fe.defendantID = pa.defendantID
   WHERE pa.arcDate BETWEEN '2018-01-01' AND '2019-12-31'
   AND fe.caseType <> 'Extradition'
),
bail AS (
SELECT TimePeriod,
	   scrTopCat,
       SUM(CASE WHEN (BailRequested = 1 OR RemandRequested = 1) THEN 1 ELSE 0 END) AS BailOrRemandRequested,
	   COUNT(DISTINCT defendantID) as TotalArcByTopCat
FROM #table t
GROUP BY TimePeriod, scrTopCat
)
SELECT bail.*,
       totalArc.TotalArc
FROM bail
JOIN totalArc ON totalArc.arcPeriod = bail.TimePeriod






------------between jan 2020 and july 2020------------


IF OBJECT_ID('tempdb.dbo.#table', 'U') IS NOT NULL
DROP TABLE #table

/* 1. pull cases where bail or remand was requested */
SELECT DISTINCT 
	   fe.defendantID,
	   fe.nysid,
	   fe.name,
	   fe.docket,
	   fe.firstEvtId,
	   arcDate,
	   arcYear = YEAR(arcDate),
	   arcMonth = MONTH(arcDate),
	   pa.arcEventID,
	   pa.scrTopCat,
	   pa.scrTopChg,
	   pa.scrTopTxt,
	   pa.scrTopCMID,
	   scrTopVFO = 0,
	   BailRequested = CASE WHEN pa.BailReqAmt > 1 THEN BailReq ELSE 0 END, -- MSS: added here rather than later
	   BailSet = CASE WHEN pa.BailSetAmt > 1 THEN pa.BailSet ElSE 0 END,
	   RemandRequested = 0,
	   Remanded = CASE WHEN pa.ReleaseStatus = 'Remand' THEN 1 ELSE 0 END,
	   isBailEligible = 0,
	   TimePeriod = 'Jan 2020 to July 2020'
INTO #table
FROM planning_arraignments2 pa
JOIN planning_fe2 fe on fe.defendantID = pa.defendantID
WHERE pa.arcDate BETWEEN '2020-01-01' AND '2020-07-01'
AND fe.caseType <> 'Extradition'


UPDATE #table
SET isBailEligible = 1
FROM #table	t
JOIN EventLinkCharge elc on elc.EventID = t.firstEvtID
AND EXISTS (SELECT 1 
			  FROM planning_charges2 pc 
			  WHERE pc.chargemodificationid = elc.ChargeModificationID
			  AND isBailQualified = 1)


	 
UPDATE #table
SET RemandRequested = 1
FROM #table t
WHERE EXISTS (SELECT 1
			FROM Evt
			JOIN EventLinkBailDetail ebd ON ebd.EventID = Evt.BailRequestEventId
			JOIN BailRequestTypeLU req ON req.BailRequestTypeId = ebd.BailRequestTypeID
			WHERE
				Evt.DefendantID = t.DefendantId 
			AND Evt.EventTypeID IN (2, 9, 165) --ecab, arc, youth part arc
			AND req.BailRequestType = 'Remand'
			)


UPDATE #table
SET RemandRequested = 1
FROM #table t
JOIN Planintdb.dbo.Planning_bail bail ON bail.DefendantID = t.DefendantID
WHERE
	BailReq_DMS LIKE '%remand%'
AND NOT EXISTS (SELECT 1
				FROM Evt 
				JOIN EventLinkBailDetail ebd ON ebd.EventID = Evt.BailRequestEventId
				JOIN BailRequestTypeLU brq ON brq.BailRequestTypeID = ebd.BailRequestTypeID
				WHERE
					Evt.DefendantID = t.DefendantId
				AND Evt.EventTypeID IN (2,9,165)
				)


UPDATE #table
SET scrTopVFO = 1 
FROM #table 
JOIN planning_charges2 pc on pc.chargemodificationid = #table.scrTopCMID
WHERE isVFO = 1 


UPDATE #table
SET scrTopCat = CASE WHEN scrTopCat = 'Felony' and scrTopVFO = 1 THEN 'VFO'
				     WHEN scrTopCat = 'Felony' and scrTopVfo = 0 THEN 'NVF'
					 ELSE scrTopCat END
FROM #table




--how many arc were bail eligible 
--how many bail eligible arc has bail or remand requested
;WITH totalArc AS (
 SELECT DISTINCT
        arcPeriod = 'Jan 2020 to July 2020',
        COUNT(DISTINCT pa.defendantID) AS TotalArc
   FROM planning_arraignments2 pa 
   JOIN planning_fe2 fe on fe.defendantID = pa.defendantID
   WHERE pa.arcDate BETWEEN '2020-01-01' AND '2020-07-01'
   AND fe.caseType <> 'Extradition'
),
bail AS (
SELECT TimePeriod,
	   scrTopCat,
       SUM(CASE WHEN isBailEligible = 1 THEN 1 ELSE 0 END) AS BailEligible,
       SUM(CASE WHEN isBailEligible = 1 AND (BailRequested = 1 OR RemandRequested = 1) THEN 1 ELSE 0 END) AS BailEligbleAndBailOrRemandRequested,
	   SUM(CASE WHEN (BailRequested = 1 OR RemandRequested = 1) THEN 1 ELSE 0 END) AS BailOrRemandRequested,
	   COUNT(DISTINCT defendantID) as TotalArcByTopCat
FROM #table t
GROUP BY TimePeriod, scrTopCat
)
SELECT bail.*,
       totalArc.TotalArc
FROM bail
JOIN totalArc ON totalArc.arcPeriod = bail.TimePeriod


--requested bail but not eligible---

SELECT distinct scrTopChg,
       scrTopTxt,
       count(distinct defendantID) as cnt
FROM #table
WHERE isBailEligible = 0
AND (BailRequested = 1 OR RemandRequested = 1)
group by scrTopChg, scrTopTxt
order by count(distinct defendantID)  desc

/*
select * from #table where isBailEligible = 0
AND (BailRequested = 1 OR RemandRequested = 1)
and scrTopChg is not null
*/

SELECT COUNT(DISTINCT defendantID)
FROM #table
WHERE isBailEligible = 0
AND (BailRequested = 1 OR RemandRequested = 1)






------------between july 2020 and Dec 2021------------



IF OBJECT_ID('tempdb.dbo.#table', 'U') IS NOT NULL
DROP TABLE #table

/* 1. pull cases where bail or remand was requested */
SELECT DISTINCT 
	   fe.defendantID,
	   fe.nysid,
	   fe.name,
	   fe.docket,
	   fe.firstEvtId,
	   arcDate,
	   arcYear = YEAR(arcDate),
	   arcMonth = MONTH(arcDate),
	   pa.arcEventID,
	   pa.scrTopCat,
	   pa.scrTopChg,
	   pa.scrTopTxt,
	   pa.scrTopCMID,
	   scrTopVFO = 0,
	   BailRequested = CASE WHEN pa.BailReqAmt > 1 THEN BailReq ELSE 0 END, -- MSS: added here rather than later
	   BailSet = CASE WHEN pa.BailSetAmt > 1 THEN pa.BailSet ElSE 0 END,
	   RemandRequested = 0,
	   Remanded = CASE WHEN pa.ReleaseStatus = 'Remand' THEN 1 ELSE 0 END,
	   isBailEligible = 0,
	   TimePeriod = 'July 2020 to Dec 2021'
INTO #table
FROM planning_arraignments2 pa
JOIN planning_fe2 fe on fe.defendantID = pa.defendantID
WHERE pa.arcDate BETWEEN '2020-07-02' AND '2021-12-31'
AND fe.caseType <> 'Extradition'


UPDATE #table
SET isBailEligible = 1
FROM #table	t
JOIN EventLinkCharge elc on elc.EventID = t.firstEvtID
AND (EXISTS (SELECT 1 
			  FROM planning_charges2 pc 
			  WHERE pc.chargemodificationid = elc.ChargeModificationID
			  AND isBailQualified = 1)
  OR EXISTS (SELECT 1 
			  FROM PLANINTDB.dbo.sabrinalist s 
			  WHERE s.CMID = elc.ChargeModificationID
			  AND [is Bail Qualified] = 1)
			  )
	 
UPDATE #table
SET RemandRequested = 1
FROM #table t
WHERE EXISTS (SELECT 1
			FROM Evt
			JOIN EventLinkBailDetail ebd ON ebd.EventID = Evt.BailRequestEventId
			JOIN BailRequestTypeLU req ON req.BailRequestTypeId = ebd.BailRequestTypeID
			WHERE
				Evt.DefendantID = t.DefendantId 
			AND Evt.EventTypeID IN (2, 9, 165) --ecab, arc, youth part arc
			AND req.BailRequestType = 'Remand'
			)


UPDATE #table
SET RemandRequested = 1
FROM #table t
JOIN Planintdb.dbo.Planning_bail bail ON bail.DefendantID = t.DefendantID
WHERE
	BailReq_DMS LIKE '%remand%'
AND NOT EXISTS (SELECT 1
				FROM Evt 
				JOIN EventLinkBailDetail ebd ON ebd.EventID = Evt.BailRequestEventId
				JOIN BailRequestTypeLU brq ON brq.BailRequestTypeID = ebd.BailRequestTypeID
				WHERE
					Evt.DefendantID = t.DefendantId
				AND Evt.EventTypeID IN (2,9,165)
				)


UPDATE #table
SET scrTopVFO = 1 
FROM #table 
JOIN planning_charges2 pc on pc.chargemodificationid = #table.scrTopCMID
WHERE isVFO = 1 


UPDATE #table
SET scrTopCat = CASE WHEN scrTopCat = 'Felony' and scrTopVFO = 1 THEN 'VFO'
				     WHEN scrTopCat = 'Felony' and scrTopVfo = 0 THEN 'NVF'
					 ELSE scrTopCat END
FROM #table




--how many arc were bail eligible 
--how many bail eligible arc has bail or remand requested
;WITH totalArc AS (
 SELECT DISTINCT
        arcPeriod = 'July 2020 to Dec 2021',
        COUNT(DISTINCT pa.defendantID) AS TotalArc
   FROM planning_arraignments2 pa 
   join planning_fe2 fe on fe.defendantID= pa.defendantID
   WHERE pa.arcDate BETWEEN '2020-07-02' AND '2021-12-31'
   AND fe.caseType <> 'Extradition'
),
bail AS (
SELECT TimePeriod,
	   scrTopCat,
       SUM(CASE WHEN isBailEligible = 1 THEN 1 ELSE 0 END) AS BailEligible,
       SUM(CASE WHEN isBailEligible = 1 AND (BailRequested = 1 OR RemandRequested = 1) THEN 1 ELSE 0 END) AS BailEligbleAndBailOrRemandRequested,
	   SUM(CASE WHEN isBailEligible = 0 AND (BailRequested = 1 OR RemandRequested = 1) THEN 1 ELSE 0 END) AS BailIneligbleAndBailOrRemandRequested,
	   SUM(CASE WHEN (BailRequested = 1 OR RemandRequested = 1) THEN 1 ELSE 0 END) AS BailOrRemandRequested,
	   COUNT(DISTINCT defendantID) as TotalArcByTopCat
FROM #table t
GROUP BY TimePeriod, scrTopCat
)
SELECT bail.*,
       totalArc.TotalArc
FROM bail
JOIN totalArc ON totalArc.arcPeriod = bail.TimePeriod



--requested bail but not eligible---

SELECT distinct scrTopChg,
       scrTopTxt,
       count(distinct defendantID) as cnt
FROM #table
WHERE isBailEligible = 0
AND (BailRequested = 1 OR RemandRequested = 1)
group by scrTopChg, scrTopTxt
order by count(distinct defendantID)  desc




/****** Script for Third Party Submitted claims matched with Prescriptions command from SSMS  ******/
/****** Script designed by Donnie Gray gdonaldgray@gmail.com******/
/* Summary:
Script combines data from electronic claim submissions with data from the prescriptions those submissions are for.
It filters out claims that were rejected (rsp status 'R') by filtering *for* claims that were adjudicated or paid (rsp status 'A' and 'P', respectively)
It also filters out claim reversals (rectype 'R') as well as whichever claim was most recently sent prior to a reversal.
The filtering functions via a lag statement which specifically reports the most recent submitted datetime prior to a particular reversal, and then outer left joins with the same table looking specifically for items that didn't fit the previous criteria. */
SELECT e.[Submitted]
      ,e.[RecType]
      ,e.[PharmID]
      ,e.[RxNo]
      ,e.[FacID]	
      ,e.[PatID]
      ,e.[Payor]
      ,e.[NDC]
      ,e.[DispenseDt]
      ,e.[Qty]
      ,e.[InsID]
      ,e.[Request]
      ,e.[Response]
      ,e.[HdrStatus]
      ,e.[RspStatus]
      ,e.[AuthNo]
      ,e.[PatientPayAmt]
      ,e.[IngredCostPd]
      ,e.[ContractFeePd]
      ,e.[SalesTaxPd]
      ,e.[TtlAmtPd]
	  ,r.[TtlPrice]
      ,e.[Msg]
      ,e.[SubmittedBy]
      ,e.[RxBatch]
      ,e.[DispFeePd]
      ,e.[ReimbursementBasis]
      ,e.[SubmitGuid]
      ,e.[RxGuid]
      ,e.[ParentGuid]
      ,e.[ts]
  FROM (
  SELECT er.* FROM [FwReports].[dbo].[ECSHistory] er
  LEFT OUTER JOIN
  (SELECT ep.rxno, ep.prevsub, ep.insid 
  FROM (SELECT *, lag(submitted) over (order by rxno, submitted asc) as 'PrevSub' FROM [fwreports].[dbo].[ECSHistory] 
  WHERE submitted > '06/01/2024') ep --Update to reflect same submitted date for lowest WHERE clause. This is to improve efficiency
  WHERE rectype = 'R') ea
  on ea.rxno = er.rxno and ea.PrevSub = er.submitted and ea.insid = er.insid
  WHERE er.RspStatus in ('A', 'P') and er.RecType = 'C' and ea.rxno is null) e
  left join [Rx].[dbo].[Rxs] r on e.RxNo = r.RxNo
  WHERE Submitted > '06/01/2024'
  order by rxno, submitted desc
  
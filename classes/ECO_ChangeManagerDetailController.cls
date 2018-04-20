public class ECO_ChangeManagerDetailController {
    
    public ChangeManager__c changeManager {get;set;}
    public ApexPages.StandardController changeManagerStandardController {get;set;}
    public pse__Proj__c project {get; set;}
    public String recordTypeId; 
    public String recordTypeName {get; set;}
    public Boolean isApproved {get; set;}
    public String mode {get; set;}
    public List<VendorSite__c> listOfVendorSites {get;set;}
    private List<String> changeManagerSubmittedIds {get; set;}
    private Boolean isSubmitted {get; set;}
    public String projectMsg {get; set;}
    public String taskMsg {get; set;}
    public String keyMemberMsg {get; set;}
    public String customersMsg {get; set;}
    public String projectSynchMessages {get; set;}
    public String projectWarningMessages {get; set;}
    public String mostRecentIMQStatus {get; set;}
	public Boolean isAdminResync {get; set;}
    public Boolean needOracleLogin {get; set;}
    
    public transient List<ECO_Service_ChangeManagerValidation.RecordLevelValidation> invalidTasks {get;set;}
    public transient List<ECO_Service_ChangeManagerValidation.RecordLevelValidation> invalidCustomers {get;set;}
    public transient List<ECO_Service_ChangeManagerValidation.RecordLevelValidation> invalidKeyMembers {get;set;}

    public String OracleUserName {get; set;}
    public String OraclePassword {get; set;}
    public String authenticationResult {get; set;}
    public Boolean pollMessageQueue {get; set;}
    public Boolean showPollingMsg {get; set;}
    public String pollingMessageQueueMsg {get; set;}
    public String pollingMessageQueueMsgBottom {get; set;}
    public String changeManagerAgreementValidationMessages {get; set;}
    public Boolean showContributingFactorValidations {get; set;}
    public string PTMValidationMessage {get;set;}
    
    public Integer numSuccessfulSyncs {get; private set;}
    public Integer numFailedAttemptedSyncs {get; private set;}
    public Boolean hasSyncHistory {get; private set;}
    public Integer numberOfNonValidateSyncs {get; set;}

    public Boolean hasRequestFailures {get; private set;}
    public transient List<SyncHistoryHelper> syncHistory {get; private set;}
    public transient List<SyncHistoryHelper> requestFailures {get; private set;}
    public Boolean hasSecurityMatrixError {get;set;}
    public Boolean hasReadonlyPermission {get; set;}
    public Boolean hasUpdatePermission {get; set;}
    public Boolean validationComplete {get; set;}
    public Boolean hasValidationErrors {get; set;}

    public Boolean hasFundingSyncErrors {get; set;}
    public Boolean hasBudgetSyncErrors {get; set;}
    public Boolean hasAgreementSyncErrors {get; set;}

	//US-08167
    public Boolean hasAFBValues {get;set;}//If true, this has A/F/B values

    public String budgetID {get; set;}
    public String chngId {get; set;}
    
    public Boolean isCurrentUserPM {get;set;}
    public class changeManagerWrapper {
    	public string mostRecentStatus {get;set;}
        public ChangeManager__c changeMgr {get;set;}
    }

    public PageReference escalateApproval(){
        try{

            changeManager.FlagForEscalate__c = true;
            update changeManager;

            return new PageReference('/' + changeManager.Id);

        } catch(Exception e){
            ApexPages.addMessages(e);
            
        }
        return null;
    }

    public ECO_ChangeManagerDetailController(ApexPages.StandardController controller)
    {
        hasSecurityMatrixError = false;
        PTMValidationMessage = null;
        invalidTasks = new List<ECO_Service_ChangeManagerValidation.RecordLevelValidation>();
        invalidCustomers = new List<ECO_Service_ChangeManagerValidation.RecordLevelValidation>(); 
        invalidKeyMembers = new List<ECO_Service_ChangeManagerValidation.RecordLevelValidation>();
        changeManagerSubmittedIds = new List<String>();


        mode = ApexPages.currentPage().getParameters().get('Mode');
        if(mode == null)    
            mode = '';
        changeManager = (ChangeManager__c)controller.getRecord();
        changeManagerStandardController = controller;
        chngId = String.valueOf(changeManager.Id);

        needOracleLogin = false;    
        pollMessageQueue = false;  
    }    

    public PageReference oracleSyncControl(){

        for(BudgetHeaderWrapper bhw: initialBudgetsForExecution){
            if(bhw.budgetHeader.id != budgetID){
                bhw.isSelected = false;
            }
        }

        return null;
    }

    public PageReference oracleSyncControl2(){

        if(changeManager.IsInternalChange__c) {
            for(BudgetHeaderWrapper bhw: availableAndSelectedBudgetChanges){
                if(bhw.budgetHeader.id != budgetID){
                    bhw.isSelected = false;
                }
            }
        }

        return null;
    }    

    public PageReference init()
    {         
        hasUpdatePermission = this.getUserCanEditChange();
        hasValidationErrors = false;

        recordTypeId = ApexPages.currentPage().getParameters().get('RecordType'); 
        mode = ApexPages.currentPage().getParameters().get('Mode'); 
        numSuccessfulSyncs = 0;
        numFailedAttemptedSyncs = 0;
        hasSyncHistory = false;
        numberOfNonValidateSyncs = 0;
        hasRequestFailures = false;
        
        if(recordTypeId != '' && recordTypeId != null && mode != 'View' && changeManager.ApprovalStatus__c != 'Sync Approved'){
            mode = 'New';
            if(hasUpdatePermission) {
                upsert changeManager;
            }
        }
        
        if(mode == 'View'){
            mode = '';
        }

        if(mode == 'New' && !hasUpdatePermission) {
            hasReadonlyPermission = true;
            return null;
        }
         
        changeManager = getChangeChangeManager();
		
		isAdminResync = false;
        if(!changemanager.IntExtContractManagement__c && !changeManager.IntExtBudget__c && changeManager.PointToPointSyncChange__c && changeManager.OracleApprovalSyncStatus__c == 'Failed') {
            //List<PermissionSetAssignment > psa = [SELECT ID FROM PermissionSetAssignment WHERE(PermissionSetId IN(SELECT ID FROM PermissionSet WHERE Name = 'epmCMP2PResync') AND AssigneeId = :UserInfo.getuserid()) limit 1];
             List<PermissionSetAssignment > psa = [SELECT ID FROM PermissionSetAssignment WHERE(PermissionSetId IN(SELECT ID FROM PermissionSet WHERE Name = 'Eco_EPM_Resend_P2P_Sync') AND AssigneeId = :UserInfo.getuserid()) limit 1];
			if (!psa.isempty()) {
                isAdminResync = true;
            }
        }
		
        hasBudgetSyncErrors = ECO_Service_ChangeManager.getHasBudgetSyncErrors(changeManager.Id);
        hasFundingSyncErrors = ECO_Service_ChangeManager.getHasFundingSyncErrors(changeManager.Id);
        hasAgreementSyncErrors = ECO_Service_ChangeManager.getHasAgreementSyncErrors(changeManager.Id);

        OracleUserName = changeManager.OracleUserName__c;
        
        if(!changeManager.IsPMHandoverChange__c && (changeManager.OracleApprovalSyncStatus__c == 'Submitted' || changeManager.OracleApprovalSyncStatus__c == 'Failed')){
            needOracleLogin = true;    
        }

        project = [select Id, Name, pse__Stage__c, pse__Project_Manager__r.pse__Salesforce_User__c, IsConverted__c, EcoSystemReferenceNumber__c, OracleProjectnumber__c, ProjectLevelFundingFlag__c, ProjectFunctionalCurrencyCode__c from pse__Proj__c where Id = :changeManager.Project__c limit 1];            

        isCurrentUserPM = (project.pse__Project_Manager__r.pse__Salesforce_User__c == Userinfo.getUserId());

        if(((changeManager.IsExecutionApprovalChange__c && !changeManager.IsExecutionApprovalPreContract__c) || changeManager.IntExtBudget__c)) {
            if(!changeManager.IntExtBudget__c) {
                populateInitialBudgetsForExecution(); 
            }
            
            populateAvailableAndSelectedBudgets();
        }

        if(changeManager.IntExtContractManagement__c) {
            populateAvailableAndSelectedFunding();
        }
       
        if(changeManager.ApprovalStatus__c != 'Submitted' && changeManager.ApprovalStatus__c != 'Approved' && hasUpdatePermission) {

            boolean bChangeManagerUpdated = false;

            if(changeManager.ProjectApprover__c == null) {
                changeManager.ProjectApprover__c = ECO_Service_ProjectTeam.getActiveProjectApproverId(changeManager.Project__c); //populateProjectApprover();
                bChangeManagerUpdated = true;
            }

            if(changeManager.ProjectAccountantApprover__c == null) {
                changeManager.ProjectAccountantApprover__c = ECO_Service_ProjectTeam.populateProjectAccountant(changeManager.Project__c);
                bChangeManagerUpdated = true;
            }

            if(changeManager.FinanceApprover__c == null) {
                changeManager.FinanceApprover__c = ECO_Service_ProjectTeam.populateProjectFinanceLead(changeManager.Project__c);  
                bChangeManagerUpdated = true;
            }

            if(changeManager.PMApprover__c == null) {
                changeManager.PMApprover__c = ECO_Service_ProjectTeam.getProjectManagerFromProjectTeam(changeManager.Project__c);
                bChangeManagerUpdated = true;
            }

            if(changeManager.ProjectApprover2__c == null) {
                changeManager.ProjectApprover2__c = ECO_Service_ProjectTeam.getActiveUserIdForProjectRole(changeManager.Project__c, 'Project Approver 2');
                bChangeManagerUpdated = true;
            }

            if(changeManager.IntExtKeyMembers__c) {
                List<ProjectTeamMember__c> projectTeamMembers = [select Id, ProjectRoleName__c, ChangeManagerIsNew__c from ProjectTeamMember__c 
                                                                where Project__c = :changeManager.Project__c 
                                                                and ChangeManagerIsNew__c = true and ProjectRoleName__c = 'Project Manager'];
                    if(!projectTeammembers.isEmpty()){
                        changeManager.PMChange__c = true;
                    }
                    else {
                        changeManager.PMChange__c = false;
                    }
            }

            if(bChangeManagerUpdated){
                ECO_ChangeManagerTriggerHandler.run = false;
                ECO_ChangeManagerTriggerHandler.handleBudgetFundingUpdate = true;
                update changeManager;
                ECO_ChangeManagerTriggerHandler.run = true;
                ECO_ChangeManagerTriggerHandler.handleBudgetFundingUpdate = false;
                RefreshChangeManager();
            }
        }

        if((changeManager.ApprovalStatus__c == '' || changeManager.ApprovalStatus__c == null || changeManager.ApprovalStatus__c == 'Cancelled' || (changeManager.ApprovalStatus__c == 'Approved' && changeManager.OracleApprovalSyncStatus__c =='Failed')) && changeManager.Project__r.pse__Stage__c == 'Planning' && changeManager.IsExecutionApprovalChange__c && changeManager.Project__r.pse__Start_Date__c != null) {
            updateTeamMembers();
        }
                
        project = [select Id, Name, IsConverted__c, EcoSystemReferenceNumber__c, pse__Stage__c, OracleProjectnumber__c, ProjectLevelFundingFlag__c, ActualAwardDate__c, Reason_Won_or_Lost__c, 
                            pse__Account__r.Name, pse__End_Date__c, pse__Start_Date__c, CarryingOutOrganization__r.Department__c, ProjectFunctionalCurrencyCode__c,
                            pse__Project_Manager__r.pse__Salesforce_User__r.EmployeeNumber, pse__Project_Manager__r.pse__Salesforce_User__c, ProjOpptyClosureStatus__c, WorkAtRiskFunding__c,
                            EnableTopTaskCustomerFlag__c
                            from pse__Proj__c where Id = :changeManager.Project__c limit 1];            
        ApexPages.currentPage().getParameters().put('projectId', changeManager.Project__c);
                 
        if(!changeManager.IsPMHandoverChange__c) {
            getSubmittedIds();
            generateSyncHistory();

            if(changeManager.IsExecutionApprovalChange__c) {
                if(changeManager.IsExecutionApprovalPreContract__c){
                    project.ProjOpptyClosureStatus__c = '5 SNB/Win/Award';
                }
                else {
                    project.ProjOpptyClosureStatus__c = '6 Contracted/Booked/Won';
                }
            }
        }
        else {
            listOfVendorSites = [select Id, Name, AccountName__c, Site__r.Account__c from VendorSite__c where Project__c = :changeManager.Project__c];  
            if(changeManager.OutgoingPM__c == null) {
                changeManager.OutgoingPM__c = changeManager.ProjectManagerId__c;
            }
        }

        //if((changeManager.OracleApprovalSyncStatus__c == 'Approved' || changeManager.ProjectSyncValidationStatus__c == 'Submitted') && changeManager.PointToPointSyncChange__c) {
        if((mostRecentIMQStatus == 'Initiated' || mostRecentIMQStatus == 'Sent') && changeManager.PointToPointSyncChange__c){
            showPollingMsg = true;
            pollMessageQueue = true;
            pollingMessageQueueMsg = Label.CheckingIfProjectHasBeenProcessed + ' <span id="pollingTimer">10</span> ' + Label.Seconds + '...';
            pollingMessageQueueMsgBottom = Label.CheckingIfProjectHasBeenProcessed + ' <span id="pollingTimer">10</span> ' + Label.Seconds + '...';  
        }
		
		//US-08167
        hasAFBValues = ECO_ChangeManagerTriggerHandler.hasAFBVariables(changeManager);
		if(hasAFBValues){
            isAdminResync = false;
		}
		
        return null;
    }  

	

    public Boolean getIsForiegnCurrencyProject()
    {
        for(Agreement__c agreement:[select FundingCurrencyCode__c, RecordType.Name, RecordType.DeveloperName from Agreement__c where Project__c = :changeManager.Project__c 
                                                and FundingCurrencyCode__c != :project.ProjectFunctionalCurrencyCode__c])
        {
            if(agreement.RecordType.DeveloperName == 'Prime' || agreement.RecordType.DeveloperName == 'PrimeTaskOrder')
                return true;
        }
        
        return false;
    }

    public Boolean getHasNonZeroARValue()
    {
        Decimal arValue = 0;
        for(Billing__c billing:[select Id, BalanceDueNumber__c from Billing__c where ProjectNumber__c = :changeManager.Project__c])
        {
            if(billing.BalanceDueNumber__c != null)
                arValue += billing.BalanceDueNumber__c;
        }

        if(arValue <> 0)
            return true;

        return false;
    }

    public Boolean getBilledAndRevenueMatch()
    {
        Decimal billedAmount = 0;
        for(Billing__c billing:[select ProjectFunctionalPreTaxInvoiceAmoun__c from Billing__c where ProjectNumber__c = :changeManager.Project__c])
        {
            if(billing.ProjectFunctionalPreTaxInvoiceAmoun__c != null)
                billedAmount += billing.ProjectFunctionalPreTaxInvoiceAmoun__c;
        }

        Decimal revenueAmount = 0;
        for(Revenue__c revenue:[select Amount__c from Revenue__c where ProjectNumber__c = :changeManager.Project__c])
        {
            if(revenue.Amount__c != null)
                revenueAmount += revenueAmount;
        }

        if(revenueAmount != billedAmount)
            return false;

        return true;
    }

    public Boolean getUserCanEditChange()
    {
        if(ECO_Service_Users.isSystemAdminstrator(UserInfo.getProfileId()) || ECO_Service_RecordAccess.getRecordAccess(changeManager.Project__c, 'ChangeManager__c')) {

            return true;
        }
        return false;
    }

    public class ChangeManagerValidationWrapper
    {
        public List<String> validationErrors {get; set;}
        public List<ECO_Service_ChangeManagerValidation.RecordLevelValidation> invalidTasks {get; set;}
        public List<ECO_Service_ChangeManagerValidation.RecordLevelValidation> invalidKeyMembers {get; set;}
        public List<ECO_Service_ChangeManagerValidation.RecordLevelValidation> invalidCustomers {get; set;}
        public List<String> validationWarnings {get; set;}

        public ChangeManagerValidationWrapper()
        {
            invalidTasks = new List<ECO_Service_ChangeManagerValidation.RecordLevelValidation>(); 
            invalidKeyMembers = new List<ECO_Service_ChangeManagerValidation.RecordLevelValidation>();
            invalidCustomers = new List<ECO_Service_ChangeManagerValidation.RecordLevelValidation>();   
        }
    }

    private static ChangeManagerValidationWrapper generateValidationsNew(ChangeManager__c remoteChangeManager)
    {
        ChangeManagerValidationWrapper wrapper = new ChangeManagerValidationWrapper();
        List<String> validationErrors = new List<String>();
        List<String> validationWarnings = new List<String>();

        validationErrors.addAll(ECO_Service_ChangeManagerValidation.validateProject(remoteChangeManager.Project__c));
        if((remoteChangeManager.IsExecutionApprovalChange__c && !remoteChangeManager.IsExecutionApprovalPreContract__c) || (!remoteChangeManager.IsExecutionApprovalChange__c && remoteChangeManager.Project__r.pse__Stage__c != 'Pre-Contract')) {
            validationErrors.addAll(ECO_Service_ChangeManagerValidation.validateBillingSites(remoteChangeManager.Project__c));
        }

        if(remoteChangeManager.IsExecutionApprovalChange__c || remoteChangeManager.IntExtProjectTasks__c) {
            ECO_Service_ChangeManagerValidation.TaskValidationWrapper taskValidation = ECO_Service_ChangeManagerValidation.validateTasks(remoteChangeManager.Project__c);
            if(taskValidation.hasValidationErrors) {
                validationErrors.addAll(taskValidation.validationMessages);
                wrapper.invalidTasks.addAll(taskValidation.invalidTasks);
            }

            if(remoteChangeManager.IsExecutionApprovalChange__c){
                validationErrors.addAll(ECO_Service_ChangeManagerValidation.validateProjectCitysForExecutionApproval(remoteChangeManager.Project__c));
                validationErrors.addAll(ECO_Service_ChangeManagerValidation.validateSubmittedExecutionApprovals(remoteChangeManager.Project__c, remoteChangeManager.Id)); 
                if(remoteChangeManager.Project__r.pse__Stage__c == 'Pending Go/No Go') {
                    validationErrors.add(Label.Project_Status_Needs_To_Be_Planning_For_Execution_Approval);
                }
		if((remoteChangeManager.BudgetIdsSelectedForExecution__c == null || remoteChangeManager.BudgetIdsSelectedForExecution__c == '') && !remoteChangeManager.IsExecutionApprovalPreContract__c) {
			validationErrors.add(Label.BudgetRequiredForExecutionApproval);
		}
            }
        }  

        if(remoteChangeManager.PointToPointSyncChange__c) {
            List<IntegrationMessageQueue__c> validationIMQs = [select Id, Status__c from IntegrationMessageQueue__c where JobName__c = 'Project Sync Validate' and Change__c = :remoteChangeManager.Id order by CreatedDate desc];
        
            if(validationIMQs.isEmpty() || validationIMQs[0].Status__c != 'Success') {
                if(remoteChangeManager.Is_Oracle_Token_Valid__c) {
                    validationWarnings.add(Label.ProjectSyncValidationMessaged);
                }
                else {
                    validationWarnings.add(Label.ProjectSyncValidationMessaged + '  ' + Label.Token_Invalid_for_Validate_Project_Sync);
                }            
            }
        }  

        if(!remoteChangeManager.IsExecutionApprovalChange__c && remoteChangeManager.Project__r.pse__Stage__c == 'Pre-Contract' && (remoteChangeManager.IntExtContractManagement__c || remoteChangeManager.IntExtBudget__c || remoteChangeManager.IntExtCustomers__c)){
            validationErrors.add(Label.PreContractStatuswithAFB); 
        }

        //validate that there is no Work At Risk Funding for External Change
        if(remoteChangeManager.IntExtContractManagement__c && remoteChangeManager.FundingIdsSelected__c != null && remoteChangeManager.FundingIdsSelected__c != '' && (remoteChangeManager.BudgetIdsSelected__c == null || remoteChangeManager.BudgetIdsSelected__c == '')) {
            validationWarnings.add(Label.FundingWithoutBudget);
        }

        ECO_Service_ChangeManagerValidation.KeyMemberValidationWrapper keyMemberValidation = ECO_Service_ChangeManagerValidation.validateKeyMembers(remoteChangeManager.Project__c, remoteChangeManager.IsExecutionApprovalChange__c);
        if(keyMemberValidation.hasValidationErrors){
            validationErrors.addAll(keyMemberValidation.validationMessages);
            wrapper.invalidKeyMembers = keyMemberValidation.invalidKeyMembers;
        }
        
        ECO_Service_ChangeManagerValidation.ClassificationValidationWrapper classificationValidation = ECO_Service_ChangeManagerValidation.validateClassifications(remoteChangeManager.Project__c, remoteChangeManager.Project__r.CarryingOutOrganization__c);
        if(classificationValidation.hasValidationErrors) {
            validationErrors.addAll(classificationValidation.validationMessages);    
        }


        if((remoteChangeManager.IsExecutionApprovalChange__c && !remoteChangeManager.IsExecutionApprovalPreContract__c) || (!remoteChangeManager.IsExecutionApprovalChange__c && remoteChangeManager.Project__r.pse__Stage__c != 'Pre-Contract')) {
            ECO_Service_ChangeManagerValidation.CustomerValidationWrapper customerValidation = ECO_Service_ChangeManagerValidation.validateCustomers(remoteChangeManager.Project__c, remoteChangeManager.Project__r.EnableTopTaskCustomerFlag__c);
            if(customerValidation.hasValidationErrors) {
                validationErrors.addAll(customerValidation.validationMessages);
                wrapper.invalidCustomers = customerValidation.invalidCustomers;
            }   
        }

        if(remoteChangeManager.IntExtContractManagement__c || (remoteChangeManager.IsExecutionApprovalChange__c && !remoteChangeManager.IsExecutionApprovalPreContract__c)) {
            validationErrors.addAll(validateAgreementsNew(remoteChangeManager));
        }    

        validationErrors.addAll(executionApprovalAgreementFundingBudgetValidationsNew(remoteChangeManager));

        if((remoteChangeManager.IsExecutionApprovalChange__c && !remoteChangeManager.IsExecutionApprovalPreContract__c) && remoteChangeManager.BudgetIdsSelectedForExecution__c != null) {
            if(remoteChangeManager.BudgetIdsSelectedForExecution__c.contains(',')) {
                validationErrors.add(Label.ExecutionMoreThanOneBudgetSelected);
            }
            else if(remoteChangeManager.BudgetIdsSelectedForExecution__c != '') {
                List<BudgetHeader__c> selectedBudgets = [select Id, TotalRevenue__c, TotalCost__c, AppliedTotalRevenue__c, AppliedTotalRevenueDisplay__c
                                                            from BudgetHeader__c 
                                                            where Id = :remoteChangeManager.BudgetIdsSelectedForExecution__c and (AppliedTotalRevenue__c = 0 or TotalCost__c = 0)];
                                                            //and TotalCost__c = 0 and AppliedTotalRevenue__c = 0];
                if(!selectedBudgets.isEmpty()) {
                    validationErrors.add(Label.ExecutionBudgetHasZeroValue);   
                }

                //validationErrors.addAll(ECO_Service_ChangeManagerValidation.validateNegativeBugetValues(remoteChangeManager.Project__c, remoteChangeManager.BudgetIdsSelectedForExecution__c, remoteChangeManager.Id));
            }
        }
        else {
            if(remoteChangeManager.IntExtBudget__c) {
                //projectSynchMessages += ECO_Service_ChangeManagerValidation.validateUnSyncedBudgetChanges(changeManager.Id, changeManager.Project__c);

                if(!remoteChangeManager.IntExtProjectTasks__c) {
                    validationErrors.addAll(ECO_Service_ChangeManagerValidation.validateBudgetsWithNewProjectTasks(remoteChangeManager.Project__c));
                }

                if(remoteChangeManager.IntExtContractManagement__c) {
                    validationErrors.addAll(ECO_Service_ChangeManagerValidation.validateFundingAndActualReveneue(remoteChangeManager.Project__c, remoteChangeManager.FundingIdsSelected__c));
                }

                if(remoteChangeManager.HasWorkAtRiskFunding__c) {
                    validationWarnings.add(Label.WarningProjectHasWorkAtRiskFunding);
                }

                if(remoteChangeManager.IsWorkAtRiskChange__c && remoteChangeManager.IntExtContractManagement__c) {
                    validationErrors.addAll(ECO_Service_ChangeManagerValidation.validateInterimAgreementAndWorkAtRiskFunding(remoteChangeManager.Project__c));
                }

                if(remoteChangeManager.BudgetIdsSelected__c == null || remoteChangeManager.BudgetIdsSelected__c == '') {
                    validationErrors.add(Label.No_Budget_Selected);
                }
                //else {
                //    validationErrors.addAll(ECO_Service_ChangeManagerValidation.validateNegativeBugetValues(remoteChangeManager.Project__c, remoteChangeManager.BudgetIdsSelected__c, remoteChangeManager.Id));
                //}
            }

            //if(remoteChangeManager.IntExtProjectTasks__c || remoteChangeManager.IntExtKeyMembers__c) {
            validationErrors.addAll(ECO_Service_ChangeManagerValidation.validateFirstProjectManagerStartDate(remoteChangeManager.Project__c));
            //}
        }        
        wrapper.validationErrors = validationErrors;
        wrapper.validationWarnings = validationWarnings;
        
        return wrapper; 
    }

    @RemoteAction
    public static ChangeManagerValidationWrapper getValidationMessages(String changeManagerId)
    {
        ChangeManager__c remoteChangeManager = [select Id, Name, Project__c, IntExtBudget__c, IntExtContractManagement__c, IsExecutionApprovalChange__c, IntExtProjectTasks__c, Project__r.ProjectLevelFundingFlag__c,
                                                    Project__r.CarryingOutOrganization__c, Project__r.WorkAtRiskFunding__c, IsWorkAtRiskChange__c, Project__r.pse__Stage__c, 
                                                    Project__r.EnableTopTaskCustomerFlag__c, IsInternalChange__c, IsExternalChange__c, BudgetIdsSelected__c, FundingIdsSelected__c,
                                                    SubmittedIdsForApproval__c, ApprovalStatus__c, IsExecutionApprovalPreContract__c, IsReversalChange__c, IntExtCustomers__c,  
                                                    BudgetIdsSelectedForExecution__c, BudgetHeader__c, IntExtKeyMembers__c, PointToPointSyncChange__c, HasWorkAtRiskFunding__c, 
                                                    Is_Oracle_Token_Valid__c, BudgetCloseoutChange__c
                                                     from ChangeManager__c where Id = :changeManagerId];
        List<String> validationMessages = new List<String>();
        //validationMessages.add('Validation Message 1' + remoteChangeManager.Project__c + remoteChangeManager.Name);
        //validationMessages.add('Validation Message 2' + remoteChangeManager.Project__c + remoteChangeManager.Name);

        return generateValidationsNew(remoteChangeManager);
    }  

    /*private String validateProjectManagerStartDate()
    {
        List<ProjectTeamMember__c> projectManagers = [select Id, Name, TeamMemberName__c, StartDate__c, Project_Start_Date__c, ProjectForecastStartDate__c
                                                            from ProjectTeamMember__c where ProjectRoleName__c = 'Project Manager'
                                                            and Project__c = :changeManager.Project__c and Project__r.IsConverted__c = false order by ProjectForecastStartDate__c limit 1];
        if(!projectManagers.isEmpty()) {
            if(projectManagers[0].StartDate__c <> projectManagers[0].ProjectForecastStartDate__c)
                return '<li>Project Manager(' + projectManagers[0].TeamMemberName__c + ') start date(' + projectManagers[0].StartDate__c + ') is not equal to the project forecast start date(' + projectManagers[0].ProjectForecastStartDate__c + '.  Please click <a href="/' + projectManagers[0].Id + '">here</a> to modify the start date for the project manager and select "Project Team" as part of this change to prevent an Oracle Sync error.</li>';
        }

        return '';
    }*/

    private void getSubmittedIds()
    {
        if(changeManager.ApprovalStatus__c == 'Submitted')
        {
            isSubmitted = true;
            if(changeManager.SubmittedIdsForApproval__c != null)
                changeManagerSubmittedIds = changeManager.SubmittedIdsForApproval__c.split(',');
            else
                changeManagerSubmittedIds = new list<String>();
        }   
        else if(changeManager.ApprovalStatus__c == 'Approved')
        {
            isSubmitted = false;
            if(changeManager.SubmittedIdsForApproval__c != null)
                changeManagerSubmittedIds = changeManager.SubmittedIdsForApproval__c.split(',');
            else
                changeManagerSubmittedIds = new list<String>();
        }
        else
        {
            isSubmitted = false;
            changeManagerSubmittedIds = ECO_Service_ChangeManager.getChangeManagerSubmittedIds(project.Id); 
        }
    }

    //@testVisible private void updateTeamMembers()
	public void updateTeamMembers()
    {
        List<ProjectTeamMember__c> deleteTeamMembers = new List<ProjectTeamMember__c>();
        List<ProjectTeamMember__c> updateTeamMembers = new List<ProjectTeamMember__c>();

        for(ProjectTeamMember__c teamMember:[select Id, Name, StartDate__c, EndDate__c from ProjectTeamMember__c where Project__c = :changeManager.Project__c and OracleProjectRoleTypeId__c != null])
        {
            if(teamMember.EndDate__c == null)
            {
                if(changeManager.Project__r.RevisedStartDate__c != null) {
                    teamMember.StartDate__c = changeManager.Project__r.RevisedStartDate__c;
                    updateTeamMembers.add(teamMember);
                }
            }
            else
                deleteTeamMembers.add(teamMember);
        }

        if(!deleteTeamMembers.isEmpty())
        {
            try{
                delete deleteTeamMembers;  
            }
            catch(Exception e)
            {
                ECO_Service_ErrorLog.formatPageError(e, Label.ProblemDeletingInactiveTeamMembers);
                //return null;
            }
        }

        if(!updateTeamMembers.isEmpty())
        {
            try{
                update updateTeamMembers;      
            }
            catch(Exception e)
            {
                ECO_Service_ErrorLog.formatPageError(e, Label.ErrorUpdatingTeamMemberStartDates); 
                //return null; 
            }
        }
    }

    @testvisible private static List<String> executionApprovalAgreementFundingBudgetValidationsNew(ChangeManager__c remoteChangeManager)
    {
        Decimal totalRevenue = 0;
        Decimal totalFunding = 0;
        List<String> validationErrors = new List<String>();

        if(remoteChangeManager.IsExecutionApprovalChange__c && !remoteChangeManager.IsExecutionApprovalPreContract__c) {
            if(remoteChangeManager.Project__r.ProjectLevelFundingFlag__c) {
                for(BudgetHeader__c bh:[select Id, AppliedTotalRevenue__c, AppliedTotalRevenueDisplay__c From BudgetHeader__c Where Project__c = :remoteChangeManager.Project__c and Id = :remoteChangeManager.BudgetIdsSelectedForExecution__c]) {
                   totalRevenue += bh.AppliedTotalRevenue__c;
                }

                for(Funding__c funding:[select Id, AllocatedFunding__c, AllocatedAmount__c, WorkAtRiskFunding__c from Funding__c where Project__c = :remoteChangeManager.Project__c]) {
                    totalFunding += funding.AllocatedFunding__c;
                    if(funding.AllocatedFunding__c < 0) {
                        validationErrors.add(Label.Negative_Funding_Lines_Execution_APproval);
                    }

                    if(funding.WorkAtRiskFunding__c) {
                        validationErrors.add(Label.WorkAtRiskFundingNotAllowedForExecutionApproval);
                    }
                }

                if(totalRevenue != totalFunding) {
                    validationErrors.add(Label.SeletedTotalRevenueDoesNotMatchFunding + ' Total Funding: ' + totalFunding + ' Total Revenue: ' + totalRevenue);
                }
            }
            else {
                Map<Id, Decimal> fundingByTasksTotals = new Map<Id, Decimal>();
                Map<Id, Decimal> budgetRevenueByTasksTotals = new Map<Id, Decimal>();
                Set<Id> taskIds = new Set<Id>();

                for(BudgetTask__c budgetTask:[Select TotalRevenue__c, OverrideTotalRevenue__c, ProjectTask__c From BudgetTask__c Where ProjectTask__r.pse__Project__c = :remoteChangeManager.Project__c and BudgetHeader__c = :remoteChangeManager.BudgetIdsSelectedForExecution__c]) {
                    if(!budgetRevenueByTasksTotals.containsKey(budgetTask.ProjectTask__c)) {
                        taskIds.add(budgetTask.ProjectTask__c);
                        budgetRevenueByTasksTotals.put(budgetTask.ProjectTask__c, budgetTask.OverrideTotalRevenue__c);  
                    }
                    else if (budgetTask.OverrideTotalRevenue__c != null) {
                        budgetRevenueByTasksTotals.put(budgetTask.ProjectTask__c, budgetRevenueByTasksTotals.get(budgetTask.ProjectTask__c) + budgetTask.OverrideTotalRevenue__c);       
                    }
                }
                for(Funding__c funding:[select AllocatedFunding__c, AllocatedAmount__c, ProjectTask__c, WorkAtRiskFunding__c from Funding__c where Project__c = :remoteChangeManager.Project__c])
                {
                    if(!fundingByTasksTotals.containsKey(funding.ProjectTask__c)) {
                        taskIds.add(funding.ProjectTask__c);
                        fundingByTasksTotals.put(funding.ProjectTask__c, funding.AllocatedFunding__c);
                    }
                    else {
                        fundingByTasksTotals.put(funding.ProjectTask__c, fundingByTasksTotals.get(funding.ProjectTask__c) + funding.AllocatedFunding__c);
                    }
                    
                    if(funding.AllocatedFunding__c < 0) {
                        validationErrors.add(Label.Negative_Funding_Lines_Execution_APproval);
                    }

                    if(funding.WorkAtRiskFunding__c) {
                        validationErrors.add(Label.WorkAtRiskFundingNotAllowedForExecutionApproval);
                    }
                }

                Decimal fundingTaskTotal = 0;
                Decimal budgetTaskTotal = 0;
                String returnValue = '';
                for(pse__Project_Task__c task:[select Id, Name from pse__Project_Task__c where Id in :taskIds]) {
                    if(fundingByTasksTotals.containsKey(task.Id)) {
                        fundingTaskTotal += fundingByTasksTotals.get(task.Id);
                    }

                    if(budgetRevenueByTasksTotals.containsKey(task.Id))
                    {
                        if(budgetRevenueByTasksTotals.get(task.Id) != null) {
                            budgetTaskTotal += budgetRevenueByTasksTotals.get(task.Id);
                        }
                    }
                    //Updated Validation Messages for US-06714  and Created 3 custom labels - Ruby 18-Aug-2017
                    if(fundingTaskTotal != budgetTaskTotal) {
                        validationErrors.add(Label.Task+': '+task.Name + '- ' +Label.BudgetRevenueOverride+' '+budgetTaskTotal+' '+Label.TotalFundingNotMatch+' '+fundingTaskTotal+' '+Label.ForTask+' '+ Label.TaskRevenueDoesNotMatchFundingExecution);
                    }
                    fundingTaskTotal = 0;
                    budgetTaskTotal = 0;
                }
            }
        }
        else
        {
            if(remoteChangeManager.IntExtBudget__c && (remoteChangeManager.IsExternalChange__c || remoteChangeManager.IsReversalChange__c) && (remoteChangeManager.BudgetIdsSelected__c != null && remoteChangeManager.BudgetIdsSelected__c != '')) {
                if(remoteChangeManager.Project__r.ProjectLevelFundingFlag__c) {
                    String fundingIdsSelected = '';
                    if(remoteChangeManager.IntExtContractManagement__c && remoteChangeManager.FundingIdsSelected__c != null) {
                        fundingIdsSelected = remoteChangeManager.FundingIdsSelected__c;
                    }
                    return ECO_Service_ChangeManagerValidation.validateBudgetsAndProjectLevelFunding(remoteChangeManager.Project__c, remoteChangeManager.BudgetIdsSelected__c, fundingIdsSelected, remoteChangeManager.IsReversalChange__c);
                }
                else {
                    return ECO_Service_ChangeManagerValidation.validateBudgetsAndTaskLevelFunding(remoteChangeManager.Project__c, remoteChangeManager.BudgetIdsSelected__c, remoteChangeManager.FundingIdsSelected__c, remoteChangeManager.IntExtContractManagement__c, remoteChangeManager.IsReversalChange__c);
                }
            }
            
            if(remoteChangeManager.IntExtContractManagement__c && (remoteChangeManager.FundingIdsSelected__c != null  && remoteChangeManager.FundingIdsSelected__c != '')) {
                validationErrors.addall(ECO_Service_ChangeManagerValidation.validateNoSubmittedChangeManagersWithWorkAtRiskFunding(remoteChangeManager.Id, remoteChangeManager.Project__c, remoteChangeManager.FundingIdsSelected__c));
            }
        }
        return validationErrors;
    }    
    
    public PageReference authenticateCredentials()
    {
        String username = ApexPages.currentPage().getParameters().get('username');
        String password = ApexPages.currentPage().getParameters().get('password');

        ECO_IntegrationEndpoints__c cs;
        cs = ECO_IntegrationEndpoints__c.getInstance('Project Sync 2');

        String endPointUrl = cs.EndPointUrl__c;

        //OracleUserName = changeManager.OracleUserName__c;
        authenticationResult = ECO_Service_Authentication.TestProxy(endPointUrl, 'PICAction=CreateSHAKey&UserId=' + username + '&Password=' + EncodingUtil.URLENCODE(password,'UTF-8'));

        return null;
    }
    
    public void checkIfSyncHasBeenProcessed()
    {
        pollMessageQueue = true;
        IntegrationMessageQueue__c msgQueueResult = ECO_Service_ProjectSync.getMessageQueue(changeManager.LatestMessageQueueId__c);
        if(msgQueueResult == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The message queue record with Id =' + changeManager.LatestMessageQueueId__c + ' could not be found!'));
            pollMessageQueue = false;
            return;
        }

        if(msgQueueResult.Status__c.equalsIgnoreCase('Success') || msgQueueResult.Status__c.equalsIgnoreCase('Error')) {
            if(msgQueueResult.Status__c.equalsIgnoreCase('Success')){
                pollingMessageQueueMsg = Label.SyncSuccessfullyProcessed;
            }
            else {
                pollingMessageQueueMsg = Label.SyncErrorforChange + '<br/>' + msgQueueResult.ErrorMessage__c;
            } 
            pollMessageQueue = false;           
        }
        else {
            if(msgQueueResult.JobName__c == 'Project Sync Validate') {
                pollingMessageQueueMsg = 'Checking if validate project sync has been processed in <span id="pollingTimer">10</span> seconds...';
            }
            else {
                pollingMessageQueueMsg = 'Checking if project sync has been processed in <span id="pollingTimer">10</span> seconds...';
            }
        }
    }    

    public PageReference returnToProjectChanges()
    {
        PageReference pageRef = new PageReference('/apex/ECO_ProjectChangeManager?Id=' + changeManager.Project__c);
        return pageRef;
    }
    
    public PageReference closeAuthenticationWindow()
    {
        PageReference editChangeManager = new PageReference('/apex/ECO_ChangeManagerDetail?Id='+changeManager.Id);        
        editChangeManager.getParameters().put('mode', mode);
        editChangeManager.getParameters().put('retURL', '/apex/ECO_ChangeManagerDetail?Id='+changeManager.Id); 
        return editChangeManager;          
    }

    public PageReference initEdit()
    {
        PageReference editChangeManager = new PageReference('/apex/ECO_ChangeManagerDetail?Id='+changeManager.Id);        
        //editAgreement.getParameters().put('nooverride', '1');
        editChangeManager.getParameters().put('mode', 'Edit');
        editChangeManager.getParameters().put('retURL', '/apex/ECO_ChangeManagerDetail?Id='+changeManager.Id); 
        return editChangeManager; 
    }
    
    public PageReference returnToChangeManager()
    {
        PageReference editChangeManager = new PageReference('/apex/ECO_ChangeManagerDetail?Id='+changeManager.Id);        
        editChangeManager.getParameters().put('mode', 'View');
        editChangeManager.getParameters().put('retURL', '/apex/ECO_ChangeManagerDetail?Id='+changeManager.Id); 
        return editChangeManager;       
    }
    
    public PageReference ApprovePMHandover()
    {
        changeManager.ApprovalStatus__c = 'Approved';
        changeManager.PMHandoverReviewed__c = true;
        //changeManager.PMHandoverReviewedBy__c = UserInfo.getUserName();
        changeManager.PMHandoverReviewedBy__c = UserInfo.getName();
        changeManager.PMhandoverDateTimeApproved__c = DateTime.now();
        update changeManager;

        return new PageReference('/' + changeManager.Id);
    }

    public PageReference RejectPMHandover()
    {
        changeManager.ApprovalStatus__c = 'Rejected';
        update changeManager;

        return new PageReference('/' + changeManager.Id);
    }

    public PageReference SubmitProjectSyncValidation() {
        
            try{
                if(changeManager.LatestMessageQueueId__c == null || changeManager.LatestMessageQueueId__c == '') {
                    changeManager.LatestMessageQueueId__c = ECO_Service_ProjectSync.createMessageQueueForRequest(changeManager.Project__c, ECO_Service_ProjectSync.JOBNAME_PROJECT_SYNC_VALIDATE, changeManager.Id, '');           
                } else{
                    IntegrationMessageQueue__c imq = new IntegrationMessageQueue__c();
                    imq.id = changeManager.LatestMessageQueueId__c;
                    imq.Status__c = 'Initiated';
                    update imq;
                }
                changeManager.ProjectSyncValidationStatus__c = 'Submitted';
                ECO_ChangeManagerTriggerHandler.run = false;
                update changeManager;
                ECO_ChangeManagerTriggerHandler.run = true;                
                ECO_Service_ChangeManager.synchronizeProjectValidate(changeManager, changeManager.Project__c);

            }
            catch(Exception e){
                ECO_Service_ErrorLog.logException(e);
            }

        return new PageReference('/' + changeManager.Id);
    }

    /**
     * Submits change manager for approval
     *
     * @Author  NTT Data - Brent Kendall
     * @Date    2015
     *
     * @return   PageReference     
     **/
    public PageReference SubmitForApproval()
    {
        if(!changeManager.IsPMHandoverChange__c) {
            List<String> vErrors = generateValidationsNew(changeManager).validationErrors;
            if(!vErrors.isEmpty()) {
                hasValidationErrors = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.FixValidationErrorsBeforeSubmitting)); 
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, wrappers[0])); 
                return null;   
            }
        }
        List<ChangeManager__c> submittedChangeManagers;
        ECO_ServiceProjectLock.ignoreProjectLock = true;

        if(changeManager.OracleApprovalSyncStatus__c == 'Failed' || hasBudgetSyncErrors || hasAgreementSyncErrors) {
            changeManager.FailedResubmittal__c =true;
        }

        if((changeManager.IntExtProjectOnHold__c || changeManager.IsProjectRestart__c) || (changeManager.IntExtProjectClosure__c && !changeManager.IsProjectReOpen__c)) 
        {
            submittedChangeManagers = [select Id from ChangeManager__c where Project__c = :changeManager.Project__c and ApprovalStatus__c = 'Submitted'];

            if(!submittedChangeManagers.isEmpty())
            {
                if(changeManager.IntExtProjectOnHold__c && !changeManager.IsProjectRestart__c)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.OnHoldChangeWithPendingSubmits));
                }
                else
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.ProjectClosureWithPendingSubmits));                
                return null;
            }
        }
        
        //Priya: Added as part of US-04382 - Enabling Submit for Approval functionality based on the Secuirty Matrix
        Boolean hasPermissionForApprovalProcess = ECO_Service_RecordAccess.getProjectRecordAccessForApprovalProcess ('ChangeManager__c', changeManager.Project__c);
            
        if (! hasPermissionForApprovalProcess)  
        {   
            system.debug( 'No Permission for approval process' );
                  
            hasSecurityMatrixError = true;

            return null;
        }

        hasSecurityMatrixError = false;


        //Check that all approvers are active and approved
        list<ECO_Service_ProjectTeam.CheckMember> lstCheckMembers = new list<ECO_Service_ProjectTeam.CheckMember>();
        lstCheckMembers.add(new ECO_Service_ProjectTeam.CheckMember(project.id, 'Project Approver'));
        
        if(changeManager.IntExtProjectOnHold__c || changeManager.IntExtProjectClosure__c 
            || changeManager.IntExtBudget__c || changeManager.IntExtContractManagement__c 
            || changeManager.IsExecutionApprovalChange__c){

                lstCheckMembers.add(new ECO_Service_ProjectTeam.CheckMember(project.id, 'Project Accountant'));
        }
        
        if( !changeManager.IntExtProjectOnHold__c || !changeManager.IntExtProjectClosure__c){
            lstCheckMembers.add(new ECO_Service_ProjectTeam.CheckMember(project.id, 'Project Manager'));
        }

        ECO_Service_ProjectTeam.CheckMembers(lstCheckMembers);
        List<ProjectTeamMember__c> lPTM = new List<ProjectTeamMember__c>();
        
        for(ECO_Service_ProjectTeam.CheckMember chk: lstCheckMembers){
            if(chk.errormsg !=null){

                PTMValidationMessage = chk.errormsg;
                return null;
            }
            else{
                lPTM.add(chk.approvedPTM);
            }
        }
        
        if(!lPTM.isEmpty()){
            for(ProjectTeamMember__c ptm : lPTM){
                if(ptm.ProjectRole__r.Name == 'Project Approver' && changeManager.ProjectApprover__c != ptm.Contact__r.pse__Salesforce_User__c){
                    changeManager.ProjectApprover__c = ptm.Contact__r.pse__Salesforce_User__c;
                }
                if(ptm.ProjectRole__r.Name == 'Project Accountant' && changeManager.ProjectAccountantApprover__c != ptm.Contact__r.pse__Salesforce_User__c){
                    changeManager.ProjectAccountantApprover__c = ptm.Contact__r.pse__Salesforce_User__c;
                }
                if(ptm.ProjectRole__r.Name == 'Project Manager' && changeManager.PMApprover__c != ptm.Contact__r.pse__Salesforce_User__c){
                    changeManager.PMApprover__c = ptm.Contact__r.pse__Salesforce_User__c;
                }
            }
        }
        
        //requirement https://aecom--agileforce.cs15.my.salesforce.com/a1Ne000000500hU
        //US-04923
        //JTenorio Added logic to create PDF and add it as attachment
        PageReference pdf = new PageReference('/apex/ECO_ChangeManagerDetailPDF?id=' + changeManager.Id);
        
        Blob pdfBody;
        
        try {
            pdfBody = pdf.getContent();
        } catch (VisualforceException e) {
            pdfBody = Blob.valueOf('Error : this is an error');
        }
        
        Datetime myDT = Datetime.now();
        String myDate = myDT.format('h:mm a');
        
        Attachment att = new Attachment(
            Name = 'ChangeManagerDetails_' + changeManager.Id + '_' + myDate + '.pdf',
            Body = pdfBody,
            ParentId = changeManager.Id,
            ContentType = 'pdf'
        );
        
        insert att;    
        

        if(changeManager.IsPMHandoverChange__c)
        {
            changeManager.ApprovalStatus__c = 'Submitted';
            update changeManager;
        }
        else
        {
            if(changeManager.IsExecutionApprovalChange__c)
            {
                if(!changeManager.IsExecutionApprovalPreContract__c) {
                    populateSelectedBudgetsForSynch();
                }

                ECO_ProjectTriggers.run = false;
                project.Eco_Locked__c = true;
                System.debug('LOCKED');
                try{
                    update project;
                } catch(Exception e) {
                    ECO_Service_ErrorLog.formatPageError(e, Label.ProblemUpdatingProjectLock);
                }
                ECO_ProjectTriggers.run = true;
            }

            if((changeManager.IsExecutionApprovalChange__c && !changeManager.IsExecutionApprovalPreContract__c) || changeManager.IntExtBudget__c)
            {
                handleBudgetSubmission();
            }        

            if(changeManager.IsWorkAtRiskChange__c) {
                Agreement__c agreement = ECO_Service_ChangeManager.getPrimeAgreementForChangeManager(changeManager.Project__c);

                if(agreement != null) {
                    changeManager.InterimApprovalComments__c = String.valueOf(agreement.InterimApprovalComments__c);
                    changeManager.InterimApprovalCostLimit__c = String.valueOf(agreement.InterimApprovalCostLimit__c);
                    changeManager.InterimApprovalDate__c = String.valueOf(agreement.InterimApprovalDate__c);
                    changeManager.InterimApprovalExpiryDate__c = String.valueOf(agreement.InterimApprovalExpiryDate__c);
                    changeManager.InterimApprovalRevenueFeeLimit__c = String.valueOf(agreement.InterimApprovalRevenueFeeLimit__c);
                    changeManager.InterimApprovalType__c = String.valueOf(agreement.InterimApprovalType__c);
                }
            }

            list<ChangeManager__c> lstCM = new list<ChangeManager__c>();
            lstCM.add(changeManager);

            ECO_Service_Delegation.evaluateDelegation(lstCM, null);
            ECO_Service_Delegation.insertDelegations(lstCM);

                    ECO_ChangeManagerTriggerHandler.run = false;
            update changeManager;
            ECO_ChangeManagerTriggerHandler.run = true;

            //Adding try catch block Story US-07293
            try{
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();  
                req1.setComments('Submitted for Approval');
                req1.setObjectId(changeManager.Id);
                Approval.ProcessResult result = Approval.process(req1); 

                if(result.isSuccess()) {
                 //populateSelectedObjects();
                    return new PageReference('/' + changeManager.Id);
                }
            }
            catch(Exception e){
                ECO_Service_ErrorLog.formatPageError(e, Label.ECO_Error_while_Submit_for_Approval);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
            }
            
        }
        return null;

    }
 
    public PageReference PutProjectOnHold() {
        changeManager.ApprovalStatus__c = 'Approved';
        changeManager.OracleApprovalSyncStatus__c = 'Approved';
        update changeManager;

        return new PageReference('/' + changeManager.Id);
    }

    public pageReference cancelChangeManager() {
        ECO_ChangeManagerTriggerHandler.handleBudgetFundingUpdate = true;
        changeManager.ApprovalStatus__c = 'Cancelled';
        changeManager.OracleApprovalSyncStatus__c = 'Cancelled';
        changeManager.FundingIdsSelected__c =  '';
        changeManager.BudgetIdsSelected__c =  '';
        changeManager.BudgetHeader__c = null;
        changeManager.IntExtBudget__c = false;
        changeManager.IntExtContractManagement__c = false;
        update changeManager;
        return null;   
    }

    public PageReference viewProjectClosureRequest() {
        PageReference closureRequest = new PageReference('/apex/ECO_CloseoutProjectApprovalPhase?Id='+changeManager.Project__c);        
        closureRequest.getParameters().put('nooverride', '1');
        return closureRequest;
    } 

    private static List<String> validateAgreementsNew(ChangeManager__c remoteChangeManager) {
        List<String> validationErrors = new List<String>();
        if(remoteChangeManager.IsInternalChange__c && !remoteChangeManager.BudgetCloseoutChange__c && (remoteChangeManager.BudgetIdsSelected__c != null && remoteChangeManager.BudgetIdsSelected__c != '')) {
            validationErrors.add(Label.AgreementAndFundingNotAllowedToBeSubmittedWithEAC);
        }
        else {
            List<Id> submittedIds = new List<Id>();
            if(remoteChangeManager.SubmittedIdsForApproval__c != null && remoteChangeManager.SubmittedIdsForApproval__c != '') {
                remoteChangeManager.SubmittedIdsForApproval__c = remoteChangeManager.SubmittedIdsForApproval__c.replace('null,', '');
                submittedIds = remoteChangeManager.SubmittedIdsForApproval__c.split(',');
            }
            
            List<Agreement__c> agreements;

            if(remoteChangeManager.IsExecutionApprovalChange__c) {
                agreements = ECO_Service_ChangeManager.getProjectAgreements(remoteChangeManager.Project__c);
            }
            else {
                agreements = ECO_Service_ChangeManager.getChangedAgreements(remoteChangeManager.Project__c, submittedIds, remoteChangeManager.ApprovalStatus__c == 'Submitted');
            }

            if(agreements == null) {
                return new List<String>();
            }

	        Set<Id> billingAccountIds = new Set<Id>();
	        Set<Id> newBillingAccountIds = new Set<Id>();
	
	        if(remoteChangeManager.Project__c != null){
	            for(Project_Site__c projectSite:[select Site__r.Account__r.Id, ChangeManagerIsNew__c from Project_Site__c where Project__c = :remoteChangeManager.Project__c and Is_Billing__c = true]) {
	                billingAccountIds.add(projectSite.Site__r.Account__r.Id);
	                if(projectSite.ChangeManagerIsNew__c) {
	                    newBillingAccountIds.add(projectSite.Site__r.Account__r.Id);
	                }
	            }
	        }     

	        for(Agreement__c agreement:agreements)
	        {
	            if(agreement.TotalApprovedRevenueLimit__c == null && agreement.RecordType.DeveloperName == 'Prime') {
	                validationErrors.add(Label.TotalApprovedRevenueLimitNeedsToBePopulated);
	            }
	            if(!billingAccountIds.contains(agreement.Account__c) && (agreement.RecordType.DeveloperName == 'Prime' || agreement.RecordType.DeveloperName == 'PrimeTaskOrder')) {
	                validationErrors.add(Label.AgreementBillingCientNotValidCustomerForProject);
	            }
	            if(!remoteChangeManager.IsExecutionApprovalChange__c && newBillingAccountIds.contains(agreement.Account__c) && !remoteChangeManager.IntExtCustomers__c) {
	                validationErrors.add(Label.NewBillingCustomerAssociatedToAgreement);
	            }
	            if(remoteChangeManager.IsExecutionApprovalChange__c && agreement.AdditionalFundingCount__c > 0) {
	                validationErrors.add(Label.FundingLinesNeedToBeAllocationType);
	            }
	        }
        }
        return validationErrors;
    }
    
    @RemoteAction
    public static changeManagerWrapper refreshData(Id changeManagerId){
        changeManagerWrapper cmw = new changeManagerWrapper();
            
        ECO_Utils_Meta.SelectAll soUtil = new ECO_Utils_Meta.SelectAll();
        soUtil.GetFields('ChangeManager__c');
        String queryString = soUtil.SOQL;
        queryString = querystring.replace('FROM ChangeManager__c', ',project__r.Name, project__r.pse__Start_Date__c, project__r.RevisedStartDate__c, project__r.pse__Stage__c, project__r.OracleProjectNumber__c, RecordType.Id, Project__r.ChangeManagerClientsRequirements__c, Project__r.ChangeManagerAECOMRequirements__c, Project__r.ProjectLevelFundingFlag__c, Project__r.CarryingOutOrganization__c, Project__r.WorkAtRiskFunding__c, Project__r.EnableTopTaskCustomerFlag__c,  toLabel(RecordType.Name), RecordType.DeveloperName FROM ChangeManager__c');
        queryString += ' WHERE Id = \''+ changeManagerId +'\'';
            
        list<ChangeManager__c> changeManagers = Database.query(queryString);
        cmw.changeMgr = changeManagers[0];
            
            
        Set<String> allStatus = new Set<String>{ ECO_Service_ProjectSync.STATUS_SUCCESS,ECO_Service_ProjectSync.STATUS_ERROR, ECO_Service_ProjectSync.STATUS_INITIATED, ECO_Service_ProjectSync.STATUS_ATTEMPTED, ECO_Service_ProjectSync.STATUS_SENT };
        List<IntegrationMessageQueue__c> allProjSyncValSyncHistory = [SELECT ErrorMessage__c, JobName__c, RecordCount__c, RecordId__c, Status__c, SuccessMessage__c,
                                                                             CreatedById, CreatedBy.Name, CreatedDate, LastModifiedDate
                                                                        FROM IntegrationMessageQueue__c
                                                                       WHERE Change__c = :changeManagerId
                                                                         AND Status__c IN :allStatus 
                                                                         AND (JobName__c = 'Project Sync Validate' OR JobName__c = 'Project Sync')
                                                                       ORDER By LastModifiedDate DESC];
        //List<IntegrationMessageQueue__c> allSyncHistory = ECO_Service_ProjectSync.getProjectSyncHistoryByChangeManager(changeManager.Id, allStatus); 
        if(!allProjSyncValSyncHistory.isEmpty())
            cmw.mostRecentStatus = allProjSyncValSyncHistory[0].Status__c;
        system.debug('cmw:'+cmw);
        return cmw;
    }

    public void RefreshChangeManager() {
        changeManager = getChangeChangeManager();
        generateSyncHistory();
    }

    public boolean getShowApprovalProcessList() {
        List<ProcessInstance> processInstanceList = [SELECT Id
                                                    FROM ProcessInstance 
                                                    WHERE TargetObjectId = :changeManager.Id];

        if(processInstanceList.isEmpty()) {
            return false;
        }

        return true;
    }    
    
    private ChangeManager__c getChangeChangeManager() {
        ECO_Utils_Meta.SelectAll soUtil = new ECO_Utils_Meta.SelectAll();
        soUtil.GetFields('ChangeManager__c');
        String queryString = soUtil.SOQL;
        queryString = querystring.replace('FROM ChangeManager__c', ',project__r.Name, project__r.pse__Start_Date__c, project__r.RevisedStartDate__c, project__r.pse__Stage__c, project__r.OracleProjectNumber__c, RecordType.Id, Project__r.ChangeManagerClientsRequirements__c, Project__r.ChangeManagerAECOMRequirements__c, Project__r.ProjectLevelFundingFlag__c, Project__r.CarryingOutOrganization__c, Project__r.WorkAtRiskFunding__c, Project__r.EnableTopTaskCustomerFlag__c,  toLabel(RecordType.Name), RecordType.DeveloperName FROM ChangeManager__c');
        queryString += ' WHERE Id = \''+ changeManager.Id +'\'';
        
        list<ChangeManager__c> changeManagers = Database.query(queryString);
        changeManager = changeManagers[0];
        
        return changeManager;
    }
    
    public PageReference createNewChangeManager() {
        PageReference returnPR;
        
        recordTypeId = ApexPages.currentPage().getParameters().get('RecordType'); 
        return null;
    }
    
    public list<pse__Proj__c> getChangedProject() {
        list<pse__Proj__c> projects = [select Id, Name, CreatedDate, CreatedById, LastModifiedById, LastModifiedDate from pse__Proj__c 
                                        where Id = :project.Id 
                                        and ChangeManagerIsChanged__c = true];
        
        if(projects.isEmpty())
            return null;
        return projects;
    }
    
    public list<pse__Project_Task__c> getChangedTasks() {
        list<pse__Project_Task__c> tasks = ECO_Service_ChangeManager.getChangedTasks(project.Id, changeManagerSubmittedIds, isSubmitted );
        
        if(tasks.isEmpty())
            return null;    
        return tasks;
    }
    
    public list<ProjectTeamMember__c> getChangedKeyMembers() {
        list<ProjectTeamMember__c> teamMembers = ECO_Service_ChangeManager.getChangedKeyMembers(project.Id, changeManagerSubmittedIds, isSubmitted );
                                                                                                
        if(teamMembers.isEmpty())                     
            return null;
        return teamMembers;
    }   
    
    public list<Project_Site__c> getChangedCustomers() {
        list<Project_Site__c> projectSites = ECO_Service_ChangeManager.getChangedCustomers(project.Id, changeManagerSubmittedIds, isSubmitted );
                                                
        if(projectSites.isEmpty())                        
            return null;
        return projectSites;

    }   
    
    public list<ECO_Service_ProjectSync.OR_Classification> getChangedClassifications() {
        ECO_Utils_Meta.SelectAll soUtil = new ECO_Utils_Meta.SelectAll();
        soUtil.GetFields('pse__Proj__c');
        String queryString = soUtil.SOQL;
        queryString += ' WHERE Id = \''+ changeManager.Project__c +'\'';
        queryString += ' and ChangeManagerIsChangedClass__c = true';
        list<pse__Proj__c> projects = Database.query(queryString);
         
        if(projects.isEmpty())
            return null;

        return ECO_Service_ProjectSync.getOracleClassificationCollection(projects[0], ECO_Utils_sObject.getFieldSetMembers('ECO_OracleClassificationFields', 'pse__Proj__c'));
    }  
        
    public list<pse__Proj__c> getChangedSafetyHealthEnv() {        
        list<pse__Proj__c> projects = ECO_Service_ChangeManager.getChangedSafetyHealthEnv(project.Id);
        
        if(projects.isEmpty())
            return null;

        return projects;     
    }
    
    public list<pse__Proj__c> getChangedResilience() {
        list<pse__Proj__c> projects = ECO_Service_ChangeManager.getChangedResilience(project.Id);
        
        if(projects.isEmpty())
            return null;

        return projects;   
    }   
    
    public list<Risk__c> getChangedRiskManagement() {
        list<Risk__c> risks = ECO_Service_ChangeManager.getChangedRiskManagement(project.Id, changeManagerSubmittedIds, isSubmitted );
        
        if(risks.isEmpty())
            return null;
        return risks;
    }
    
    public list<Agreement__c> getChangedAgreements() {
 
        list<Agreement__c> agreements = ECO_Service_ChangeManager.getChangedAgreements(project.Id, changeManagerSubmittedIds, isSubmitted );
        
        if(agreements.isEmpty())
            return null;

        return agreements;   
    }
    
    public list<Agreement__c> getSubmittedAgreements() {
        list<Agreement__c> agreements = ECO_Service_ChangeManager.getSubmittedAgreements(project.Id, changeManagerSubmittedIds );
        
        if(agreements.isEmpty())
            return null;

        return agreements;   
    }    
    
    public list<Funding__c> getSubmittedContractManagementFunding() {
        list<Funding__c> fundings = ECO_Service_ChangeManager.getSubmittedFunding(project.Id, changeManagerSubmittedIds, changeManager.Id );
        
        if(fundings.isEmpty())
            return null;
        return fundings;        
    }

    public list<Funding__c> getChangedContractManagementFunding() {
        list<Funding__c> fundings = ECO_Service_ChangeManager.getChangedFunding(project.Id, changeManagerSubmittedIds, isSubmitted );
        
        if(fundings.isEmpty())
            return null;
        return fundings;        
    }
    
    public list<Packages__c> getChangedScope() {
        list<Packages__c> scopes = ECO_Service_ChangeManager.getChangedScope(project.Id, changeManagerSubmittedIds, isSubmitted );

        if(scopes.isEmpty())
            return null;
        return scopes;
    }
                
    public BudgetHeader__c getChangedBudget() {
        list<BudgetHeader__c> budgets = [select Id, Name, BudgetName__c, TotalContingencyAmount__c, AppliedTotalRevenue__c, AppliedTotalRevenueDisplay__c, TotalCost__c, TotalRevenue__c, Status__c, Project__c, CreatedDate, CreatedById,
                                        LastModifiedDate, LastModifiedById, Project__r.Budget_OracleSyncStatus__c, Project__r.Budget_OracleSyncErrorMessage__c from BudgetHeader__c where Id = :changeManager.BudgetHeader__c];
        if(budgets.isEmpty())
            return null;
        return budgets[0];
    }   
    
    public BudgetHeader__c getInitialBudget() {
        list<BudgetHeader__c> budgets = [select Id, Name, BudgetName__c, TotalContingencyAmount__c, AppliedTotalRevenue__c, TotalCost__c, TotalRevenue__c, Status__c, Project__c, CreatedDate, CreatedById,
                                        LastModifiedDate, LastModifiedById, Project__r.Budget_OracleSyncStatus__c, Project__r.Budget_OracleSyncErrorMessage__c from BudgetHeader__c where Id = :changeManager.BudgetIdsSelectedForExecution__c];
        if(budgets.isEmpty())
            return null;
        return budgets[0];
    }   

    public boolean getProjectRestartFromOnHold() {
        if(changeManager.IntExtProjectOnHold__c && changeManager.IsProjectRestart__c)
            return true;
        return false;
    }

    public boolean getPutProjectOnHold() {
        if(changeManager.IntExtProjectOnHold__c && !changeManager.IsProjectRestart__c)
            return true;
        return false;
    }


    public list<pse__Proj__c> getChangedProjectClosure() {

        list<pse__Proj__c> projects = ECO_Service_ChangeManager.getChangedProjectClosure(changeManager.Project__c);
    
        if(projects.isEmpty())
            return null;
        return projects;
    }
        
    public class BudgetHeaderWrapper {
        public Boolean isSelected {get; set;}
        public BudgetHeader__c budgetHeader {get; set;}
        public Boolean isLocked {get; set;}

        public BudgetHeaderWrapper(Boolean selected, BudgetHeader__c budgetHeader) {
            this.isSelected = selected;
            this.budgetHeader = budgetHeader;
            this.isLocked = false;
        }

        public BudgetHeaderWrapper(Boolean selected, BudgetHeader__c budgetHeader, Boolean locked) {
            this.isSelected = selected;
            this.budgetHeader = budgetHeader;
            this.isLocked = locked;
        }
    }

    public class FundingWrapper {
        public Boolean isSelected {get; set;}
        public Funding__c funding {get; set;}
        public Boolean isLocked {get; set;}

        public FundingWrapper(Boolean selected, Funding__c funding, Boolean locked) {
            this.isSelected = selected;
            this.funding = funding;
            this.isLocked = locked;
        }
    }

    public List<BudgetHeaderWrapper> availableAndSelectedBudgetChanges {get; set;}

    public List<BudgetHeaderWrapper> initialBudgetsForExecution {get; set;}

    public List<FundingWrapper> availableAndSelectedFundingChanges;

    public List<FundingWrapper> getAvailableAndSelectedFundingChanges() {
        populateAvailableAndSelectedFunding();
        return availableAndSelectedFundingChanges;
    }

    public void populateAvailableAndSelectedBudgets() {
        availableAndSelectedBudgetChanges = new List<BudgetHeaderWrapper>();

        if(changeManager.BudgetIdsSelected__c == null) {
            changeManager.BudgetIdsSelected__c = '';
        }

        if(changeManager.BudgetIdsApproved__c == null) {
            changeManager.BudgetIdsApproved__c = '';
        }

        Boolean locked;
        Boolean selected;
        List<BudgetHeader__c> availableBudgets = ECO_Service_ChangeManager.getAvailableBudgets(changeManager.Project__c, changeManager.RecordType.DeveloperName, changeManager.BudgetHeader__c, changeManager.Id, changeManager.ApprovalStatus__c, hasBudgetSyncErrors);
        for(BudgetHeader__c budget:availableBudgets) {
            if(!budget.CreatedBy.Username.contains('integration@aecom.com') && !budget.CreatedBy.Username.contains('integrations@aecom.com')){
                //if(changeManager.BudgetIdsSelected__c.contains(budget.Id)) {
                selected = changeManager.BudgetIdsSelected__c.contains(budget.Id);
                locked = changeManager.BudgetIdsApproved__c.contains(budget.Id);
                availableAndSelectedBudgetChanges.add(new BudgetHeaderWrapper(selected, budget, locked));
                //}
                //else {
                
                //availableAndSelectedBudgetChanges.add(new BudgetHeaderWrapper(false, budget));   
                //}
            }
        }
    }

    public void populateAvailableAndSelectedFunding() {
        availableAndSelectedFundingChanges = new List<FundingWrapper>();

        if(changeManager.FundingIdsSelected__c == null) {
            changeManager.FundingIdsSelected__c = '';
        }   

        if(changeManager.FundingIdsApproved__c == null) {
            changeManager.FundingIdsApproved__c = '';
        }   

        Boolean locked;
        Boolean selected;
        List<Funding__c> availableFunding = ECO_Service_ChangeManager.getAvailableFunding(changeManager.Project__c, changeManager.RecordType.DeveloperName, changeManager.Id, changeManager.ApprovalStatus__c);
        for(Funding__c funding:availableFunding) {
            selected = changeManager.FundingIdsSelected__c.contains(funding.Id);
            locked = changeManager.FundingIdsApproved__c.contains(funding.Id);
            availableAndSelectedFundingChanges.add(new FundingWrapper(selected, funding, locked));
        }
    }

    public void populateInitialBudgetsForExecution() {
        initialBudgetsForExecution = new list<BudgetHeaderWrapper>();

        if(changeManager.BudgetIdsSelectedForExecution__c == null){
            changeManager.BudgetIdsSelectedForExecution__c = '';
        }
            
        for(BudgetHeader__c budget:[select Id, Name, BudgetName__c, TotalCost__c, TotalRevenue__c, AppliedTotalRevenue__c, AppliedTotalRevenueDisplay__c, LastModifiedById, LastModifiedDate from BudgetHeader__c where Project__c = :changeManager.Project__c and Status__c = 'Draft']) {
            if(changeManager.BudgetIdsSelectedForExecution__c == null || changeManager.BudgetIdsSelectedForExecution__c == '') {
                initialBudgetsForExecution.add(new BudgetHeaderWrapper(true, budget));
                changeManager.BudgetIdsSelectedForExecution__c = budget.Id; 
            }
            else {   
                if(changeManager.BudgetIdsSelectedForExecution__c.contains(budget.Id)) {
                    initialBudgetsForExecution.add(new BudgetHeaderWrapper(true, budget));                
                }
                else {
                    initialBudgetsForExecution.add(new BudgetHeaderWrapper(false, budget));
                }
            }
        }
    }
    
    public list<VendorSite__c> getChangedResources() {
        list<VendorSite__c> subsAndVendors = ECO_Service_ChangeManager.getChangedResources(changeManager.Project__c, changeManagerSubmittedIds, isSubmitted);
        
        if(subsAndVendors.isEmpty())
            return null;
        return subsAndVendors;
    }
    
    public list<Deliverable__c> getChangedDeliverables() {
        list<Deliverable__c> deliverables = ECO_Service_ChangeManager.getChangedDeliverables(changeManager.Project__c, changeManagerSubmittedIds, isSubmitted);

        if(deliverables.isEmpty())
            return null;
        return deliverables;
    }
    
    public list<pse__Proj__c> getChangedDocumentManagement() {
        list<pse__Proj__c> projects = ECO_Service_ChangeManager.getChangedDocumentManagement(changeManager.Project__c);

        if(projects.isEmpty())
            return null;

        return projects;            
    }
    
    public list<Stakeholder__c> getChangedStakeholders() {
        list<Stakeholder__c> stakeholders = ECO_Service_ChangeManager.getChangedStakeholders(changeManager.Project__c, changeManagerSubmittedIds, isSubmitted);
        
        if(stakeholders.isEmpty())
            return null;
        return stakeholders;
    }
    
    public PageReference returnToProject() {
        return new PageReference('/' + changeManager.Project__c);
    }
    
    public list<SelectOption> getYesNoOptions() {
        list<SelectOption> options = new list<SelectOption>();
        options.add(new SelectOption('Yes', 'Yes'));
        options.add(new SelectOption('No', 'No'));
    
        return options;
    }
        
    public PageReference editChangeManager() {
        mode = 'Edit';
        return null; 
    }
	
	public PageReference handleAdminResync() {

        ECO_IntegrationMessageQueueTriggers.run = false;
        IntegrationMessageQueue__c imq = new IntegrationMessageQueue__c(Id = changemanager.LatestMessageQueueId__c, JobName__c = 'Project Sync', Status__c = 'Initiated', ErrorMessage__c = '');
        update imq;
        pollMessageQueue = true;
        mostRecentIMQStatus = 'Initiated';
        showPollingMsg = true;
        pollingMessageQueueMsg = Label.CheckingIfProjectHasBeenProcessed + ' <span id="pollingTimer">10</span> ' + Label.Seconds + '...';
        pollingMessageQueueMsgBottom = Label.CheckingIfProjectHasBeenProcessed + ' <span id="pollingTimer">10</span> ' + Label.Seconds + '...';  

        ECO_IntegrationMessageQueueTriggers.run = true;

        ECO_ChangeManagerTriggerHandler.run = false;
        changeManager.OracleApprovalSyncStatus__c = 'Approved';
        update changeManager;

        ECO_Service_ChangeManager.synchronizeProject(changeManager, changeManager.Project__c);

        ECO_ChangeManagerTriggerHandler.run = true;

        return null;
    } 

    private void populateSelectedBudgetsForSynch() {
        String selectedIds = '';
        if(initialBudgetsForExecution != null && changeManager.IsExecutionApprovalChange__c){
            for(BudgetHeaderWrapper wrapper:initialBudgetsForExecution) {
                if(wrapper.isSelected && selectedIds == '') {
                    selectedIds = wrapper.budgetHeader.Id;
                }
                else if(wrapper.isSelected && changeManager.BudgetIdsSelectedForExecution__c != '' ) {
                    selectedIds += ',' + wrapper.budgetHeader.Id;   
                }
            }
            changeManager.BudgetIdsSelectedForExecution__c = selectedIds;

            if(selectedIds != '') {
                changeManager.BudgetHeader__c = selectedIds;
                changeManager.BudgetIdsSelected__c = selectedIds;
            }
        }

        selectedIds = '';
        if(availableAndSelectedBudgetChanges != null) {
            for(BudgetHeaderWrapper wrapper:availableAndSelectedBudgetChanges) {
                if(wrapper.isSelected) {
                    if(selectedIds == '') {
                        selectedIds = wrapper.budgetHeader.Id;
                    }
                    else {
                        selectedIds += ',' + wrapper.budgetHeader.Id;
                    }
                } 
            }

            if(selectedIds != '') {
                changeManager.BudgetIdsSelected__c = selectedIds;
                if(changeManager.BudgetHeader__c != null && !selectedIds.contains(changeManager.BudgetHeader__c)) {
                    changeManager.BudgetHeader__c = null; 
                }
            }
            else {
                changeManager.BudgetIdsSelected__c = '';
            }
        }
    }

    @TestVisible private void populateSelectedFunding() {
        String selectedIds = '';
        
        if(availableAndSelectedFundingChanges != null) {
            for(FundingWrapper fundingWrapper:availableAndSelectedFundingChanges) {
                if(fundingWrapper.isSelected) {
                    if(selectedIds == '') {
                        selectedIds = fundingWrapper.funding.Id;
                    }
                    else {
                        selectedIds += ',' + fundingWrapper.funding.Id;
                    }
                }
            }

            if(selectedIds != '') {
                changeManager.FundingIdsSelected__c = selectedIds;
            }
            else {
               changeManager.FundingIdsSelected__c = ''; 
            }
        }
    }

    @TestVisible private void handleBudgetSubmission() {
        if(changeManager.BudgetHeader__c != null) {
            List<Id> selectedBudgetIds = changeManager.BudgetIdsSelected__c.split(',');
            List<BudgetHeader__c> budgetHeaders = ECO_Service_Budget.getBudgetHeaders(selectedBudgetIds);
            ECO_Service_Budget.createBudgetSubmssionSnapshots(changeManager.Id, changeManager.Project__c, budgetHeaders);
            
            for(BudgetHeader__c budgetHeader:budgetHeaders) {

                Boolean budgetHeaderApprovalStatusChanged = false;
                if(changeManager.IsExecutionApprovalChange__c || (changeManager.IsExternalChange__c && (budgetHeader.Status__c == 'Draft' || budgetHeader.Status__c == 'Forecast')))
                {
                    budgetHeader.ApprovalStatus__c = 'Submitted for Approval';
                    budgetHeader.SubmittedForApprovedStatusDate__c = Date.today();
                    budgetHeaderApprovalStatusChanged = true;

                }
                else if(changeManager.IsInternalChange__c || changeManager.IsWorkAtRiskChange__c && budgetHeader.Status__c == 'Draft' )
                {
                    budgetHeader.ApprovalStatus__c = 'Submitted for Forecast';
                    budgetHeader.SubmittedForForecastStatusDate__c = Date.today();
                    budgetHeaderApprovalStatusChanged = true;
                }
                else if(changeManager.IsReversalChange__c) {
                    budgetHeader.SubmittedForReversal__c = true;
                }
            }
            if(!budgetHeaders.isEmpty()) {
                ECO_BudgetHeaderTriggers.run = false;
                update budgetHeaders;
                ECO_BudgetHeaderTriggers.run = true;
            }
        }
    }

    public List<BudgetSubmissionSnapshot__c> getBudgetSubmissionSnapshots() {
        List<BudgetSubmissionSnapshot__c> snapshots = [select Id, Name, SubmittedByUser__c, SubmittedTimestamp__c, AppliedTotalRevenue__c, TotalContingencyAmount__c
                                                                , TotalFringe__c, TotalLaborAmount__c, TotalNonLabor__c, TotalOverhead__c, TotalRawCost__c, TotalSubAmount__c,
                                                                CurrencyIsoCode from BudgetSubmissionSnapshot__c where Change__c = :changeManager.Id];

        if(snapshots.isEmpty())
            return null;
        return snapshots;   
    }
    
    public List<Attachment> getAttachments() {
        List<Attachment> attachs = [select ParentId,Name from Attachment where ParentId = :changeManager.Id ];
        
        //https://aecom--epmdev--c.cs28.visual.force.com/apex/ECO_ChangeManagerDetailPDF?id=

        if(attachs.isEmpty())
            return null;
        return attachs;   
    }    

    public PageReference RetryOracleSync() {
        changeManager.FailedResubmittal__c = true;
        SubmitForApproval();

        return null;
    }    
    
    private Boolean isBudgetSelected() {
        if(initialBudgetsForExecution != null) {
            for(BudgetHeaderWrapper wrapper:initialBudgetsForExecution) {
                if(wrapper.isSelected) {
                    return true;
                }
            }
        }
        return false;
    }

    public Boolean getShowExecutionApprovalWarning()
    {
        if(!isBudgetSelected() || this.getChangedAgreements() == null || getChangedContractManagementFunding() == null ) {
            return true;
        }

        return false;
    }

    public PageReference saveChangeManager()
    {
        if (!hasUpdatePermission) {         
            hasReadonlyPermission = true;
            return null;
        }

        hasSecurityMatrixError = false;

        ECO_ChangeManagerTriggerHandler.run = false;
        System.Debug('DEBUG__ChanagerManagerDetailController_saveChangeManager_Start');
        
        if((changeManager.IsInternalChange__c || changeManager.IsExternalChange__c || changeManager.IsWorkAtRiskChange__c || changeManager.IsReversalChange__c) && !changeManager.IntExtProjectOnHold__c && !changeManager.IntExtProjectClosure__c) {
            showContributingFactorValidations = false;
            if(changeManager.ContributingFactor__c == null || changeManager.ContributingFactor__c == '') {
                showContributingFactorValidations = true;
                ApexPages.Message oPageMessage = new ApexPages.Message(ApexPages.Severity.ERROR, Label.ContributionFactorIsRequired);
                ApexPages.addMessage(oPageMessage);   
            }
            
            if(changeManager.ContribFactorDetails__c == null || changeManager.ContribFactorDetails__c == '') {
                showContributingFactorValidations = true;
                ApexPages.Message oPageMessage = new ApexPages.Message(ApexPages.Severity.ERROR, Label.ContributionFactorDetailsAreRequired);
                ApexPages.addMessage(oPageMessage);   
            }

            if(changeManager.IntExtBudget__c && (changeManager.IntExtBudgetComments__c == null || changeManager.IntExtBudgetComments__c == '')) {
                ApexPages.Message oPageMessage = new ApexPages.Message(ApexPages.Severity.ERROR, Label.Budget_Change_Notes_are_Required);
                ApexPages.addMessage(oPageMessage); 
                return null;
            }

            if(showContributingFactorValidations) {
                return null;
            }
        }

        try {
            if((changeManager.IsExecutionApprovalChange__c || changemanager.IntExtBudget__c)) {
                populateSelectedBudgetsForSynch();
                populateAvailableAndSelectedBudgets();
                ECO_ProjectTriggers.run = false;
                update project;
                ECO_ProjectTriggers.run = true;
            }

            if(changeManager.IntExtContractManagement__c) {
                populateSelectedFunding();
            }

            changeManager.HasWorkAtRiskFunding__c = false;
            if(changeManager.IntExtBudget__c && changeManager.IsExternalChange__c) {
                List<String> fundingIds = new List<String>();
                if(changeManager.FundingIdsSelected__c != null && changeManager.FundingIdsSelected__c != '') {
                    fundingIds.addAll(changeManager.FundingIdsSelected__c.split(','));
                }
                List<AggregateResult> results = [select Project__c, sum(AllocatedFunding__c) TotalAllocatedFunding from Funding__c where Project__c = :changeManager.Project__c and (OracleSyncStatus__c = 'S' or OracleSyncStatus__c = 'T' or Id in :fundingIds) and WorkAtRiskFunding__c = true group by Project__c];

                if(!results.isEmpty()) {
                    if((Decimal)results[0].get('TotalAllocatedFunding') != 0){
                        changeManager.HasWorkAtRiskFunding__c = true;
                    } 
                }
            }

            ECO_ChangeManagerTriggerHandler.run = false;
            ECO_ChangeManagerTriggerHandler.handleBudgetFundingUpdate = true;
            upsert changeManager;
            ECO_ChangeManagerTriggerHandler.run = true;
            ECO_ChangeManagerTriggerHandler.handleBudgetFundingUpdate = false;
        }
        catch(Exception e) {
            return null;            
        }

        mode = '';

        if(changeManager.IsPMHandoverChange__c) {
            return new PageReference('/' + changeManager.Id);
        }

        System.Debug('DEBUG__ChanagerManagerDetailController_saveChangeManager_End');
        return new PageReference('/' + changeManager.Id + '?Mode=View');
    }
    
    public PageReference takeProjectSnapshot() {
        ECO_Service_ProjectSnapshots snapshotService = new ECO_Service_ProjectSnapshots();
        snapshotService.computeSnapshots( new List<Date>{Date.today()} , new List<Id>{changeManager.Project__c});
        ProjectSnapshot__c snapshot = snapshotService.projectSnapshots.values()[0];
        snapshot.ChangeManager__c = changeManager.Id;
        upsert snapshot Snapshot_Project_Key__c;
        return null;
    }

    @TestVisible
    private void generateSyncHistory() {
        Set<String> successStatus = new Set<String>{ ECO_Service_ProjectSync.STATUS_SUCCESS };
        List<IntegrationMessageQueue__c> tmpSyncHistory = ECO_Service_ProjectSync.getProjectSyncHistoryByChangeManager(changeManager.Id, successStatus); 
        syncHistory = new List<syncHistoryHelper>();
        for(IntegrationMessageQueue__c tmpRec : tmpSyncHistory) {
            syncHistoryHelper syncHelper = new syncHistoryHelper();
            syncHelper.syncLocalDateTime = tmpRec.LastModifiedDate.format();
            syncHelper.msgQueue = tmpRec;
            syncHistory.add(syncHelper);
            if(tmpRec.JobName__c == ECO_Service_ProjectSync.JOBNAME_PROJECT_SYNC) {
                numberOfNonValidateSyncs++;
            }
        }   
        if(!syncHistory.isEmpty()) {
            hasSyncHistory = true;
        }

        Set<String> otherStatuses = new Set<String> {ECO_Service_ProjectSync.STATUS_ERROR, ECO_Service_ProjectSync.STATUS_INITIATED, ECO_Service_ProjectSync.STATUS_ATTEMPTED, ECO_Service_ProjectSync.STATUS_SENT };
        List<IntegrationMessageQueue__c> tmpRequestFailures = ECO_Service_ProjectSync.getProjectSyncHistoryByChangeManager(changeManager.Id, otherStatuses); 
        requestFailures = new List<syncHistoryHelper>();
        for(IntegrationMessageQueue__c tmpRec : tmpRequestFailures) {
            syncHistoryHelper syncHelper = new syncHistoryHelper();
            syncHelper.syncLocalDateTime = tmpRec.LastModifiedDate.format();
            syncHelper.msgQueue = tmpRec;
            requestFailures.add(syncHelper);
        }   
        if(!requestFailures.isEmpty()) {
            hasRequestFailures = true;
        }
        
        Set<String> allStatus = new Set<String>{ ECO_Service_ProjectSync.STATUS_SUCCESS,ECO_Service_ProjectSync.STATUS_ERROR, ECO_Service_ProjectSync.STATUS_INITIATED, ECO_Service_ProjectSync.STATUS_ATTEMPTED, ECO_Service_ProjectSync.STATUS_SENT };
	List<IntegrationMessageQueue__c> allProjSyncValSyncHistory = [SELECT ErrorMessage__c, JobName__c, RecordCount__c, RecordId__c, Status__c, SuccessMessage__c,
			                                                     CreatedById, CreatedBy.Name, CreatedDate, LastModifiedDate
		                                                        FROM IntegrationMessageQueue__c
	                                                               WHERE Change__c = :changeManager.Id 
	                                                                 AND Status__c IN :allStatus 
	                                                                 AND (JobName__c = 'Project Sync Validate' OR JobName__c = 'Project Sync')
	                                                               ORDER By LastModifiedDate DESC];
	//List<IntegrationMessageQueue__c> allSyncHistory = ECO_Service_ProjectSync.getProjectSyncHistoryByChangeManager(changeManager.Id, allStatus); 
	if(!allProjSyncValSyncHistory.isEmpty())
            mostRecentIMQStatus = allProjSyncValSyncHistory[0].Status__c;

        numSuccessfulSyncs = syncHistory.size();
        numFailedAttemptedSyncs = requestFailures.size();
    }    



    public string locale { get {return UserInfo.getLocale().replace('_', '-');} }

    public class syncHistoryHelper {
        public String syncLocalDateTime {get;set;}
        public IntegrationMessageQueue__c msgQueue {get;set;}
    }  

    public class SinglePageBlockChangeItem {
        public String ActionName {get;set;}
        public pse__Proj__c Project {get; set;}
    }

}
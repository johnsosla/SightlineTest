@isTest
private class ECO_ProjectTaskTriggersTest {
    public static ECO_ProjectTaskService ets { 
        get {
            if (ets == null) ets = new ECO_ProjectTaskService();

            return ets;
        }

        set;
    }

    static List<pse__Project_Task__c> tNew;
    static Map<Id, pse__Project_Task__c> tOldMap;

    @testSetup static void initTestSetup() {
     /*  ECO_ProjectTriggers.run = false;
       ECO_ProjectTaskTriggers.run = false;
        Integer numOfWeeks = 5, numOfProjectTasks = 5;
        ECO_Service_DirtyScope.run = false;
        ECO_Utils_Testing.createTestDataForBudgets();

        // ADD TASKS RELATED TO A SECOND PROJECT
        List<pse__Proj__c> projects = [select id from pse__Proj__c];
        system.assert(projects.size()>=2);
        pse__Proj__c p2 = (pse__Proj__c) projects[1];
        List<pse__Project_Task__c> pTasks = new List<pse__Project_Task__c>();
        
        for(integer i=0;i<6;i++ ){
            pTasks.add(new pse__Project_Task__c(NAME = 'DPL U 0002TASK 000'+i,
                                                            CURRENCYISOCODE='NZD',
                                                            PSE__PROJECT__c = p2.id,
                                                            PSE__START_DATE_TIME__C =DateTime.newInstanceGMT(2015, 4, 3, 4, 0, 0),
                                                            PSE__END_DATE_TIME__C = DateTime.newInstanceGMT(2016, 6, 30, 4, 0, 0),
                                                            TOTALESTIMATECOST__C = 0.0,
                                                            TOTALAPPROVEDCOST__C = 0.0,
                                                            ProjectTaskNumber__c ='1',
                                                            pse__Hierarchy_Depth__c=1,
                                                            FORECASTSTARTDATE__C = Date.newInstance(2015, 04, 03),
                                                            FORECASTENDDATE__C = Date.newInstance(2016, 06, 30),
                                                            FINANCIALTASK__C = TRUE,
                                                            EARNEDVALUE__C = 100,
                                                            CREATEDDATE = DateTime.newInstanceGMT(2015, 4, 1, 4, 0, 0)
                                                            ));
        }
        insert pTasks;

        // Create children tasks to test more lines
        List<pse__Project_Task__c> tasksToUpdate = new List<pse__Project_Task__c> ();
      
        List<pse__Project_Task__c> tasks = [select id, pse__Project__c from pse__Project_Task__c Order by pse__Project__c, name];

        //pse__Proj__c proj = new pse__Proj__c(Id = tasks[6].pse__Project__c, EnableTopTaskCustomerFlag__c = true);
        //ECO_ProjectTriggers.run = false;
        //update proj;
        //ECO_ProjectTriggers.run = true;
        
        tasks[3].OracleSyncStatus__c = 'S';
        tasks[1].pse__Parent_Task__c = tasks[3].Id;
        tasks[1].FinancialTask__c = false;
        tasks[1].isChargeable__c = false;
        tasks[1].isBillable__c = false;
        tasks[1].IsWorkPlanTask__c = true;
        tasks[1].OracleSyncStatus__c = 'P';

        tasks[2].isChargeable__c = false;
        tasks[4].pse__Parent_Task__c = tasks[2].Id;
        tasks[4].FinancialTask__c = true;
        tasks[4].isChargeable__c = true;
        tasks[4].isBillable__c = true;
        tasks[4].IsWorkPlanTask__c = false;
        tasks[4].OracleSyncStatus__c = 'P';

        //tasksToUpdate.add(tasks[1]);
        //tasksToUpdate.add(tasks[3]);
        tasksToUpdate.add(tasks[4]);
        tasksToUpdate.add(tasks[2]);
        
        update tasksToUpdate;*/
        
          ECO_Utils_Testing.createTestDataForBudgets();

        List<pse__Project_Task__c> tasksToUpdate = new List<pse__Project_Task__c> ();

        // Create children tasks to test more lines
        List<pse__Project_Task__c> tasks = [select id, pse__Project__c,pse__Start_Date__c, pse__End_Date__c,ForecastStartDate__c,ForecastEndDate__c from pse__Project_Task__c Where pse__Project__r.ORACLEPROJECTNUMBER__C = 'DPL201602090001' ];

        tasks[3].isChargeable__c = false;
        tasks[4].pse__Parent_Task__c = tasks[3].Id;
        tasks[4].FinancialTask__c = true;
        tasks[4].isChargeable__c = true;
        tasks[4].isBillable__c = true;
        tasks[4].IsWorkPlanTask__c = false;
        tasks[4].OracleSyncStatus__c = 'P';

        tasksToUpdate.add(tasks[4]);
        // tasksToUpdate.add(tasks[6]);
        tasksToUpdate.add(tasks[3]);
        update tasksToUpdate;
       
    }

    static void initData() {
        Map<String, Schema.SObjectField> fldObjMap = schema.SObjectType.pse__Project_Task__c.fields.getMap();
        List<Schema.SObjectField> fldObjMapValues = fldObjMap.values();

        String theQuery = 'SELECT ';
        for(Schema.SObjectField s : fldObjMapValues)
        {
           // String theLabel = s.getDescribe().getLabel(); // Perhaps store this in another map
           String theName = s.getDescribe().getName();
           // String theType = s.getDescribe().getType(); // Perhaps store this in another map

           // Continue building your dynamic query string
           theQuery += theName + ',';
        }

        // Trim last comma
        theQuery = theQuery.subString(0, theQuery.length() - 1);

        // Finalize query string
        theQuery += ' FROM pse__Project_Task__c';

        // Make your dynamic call
        pse__Project_Task__c[] tasks = Database.query(theQuery);
        tNew = tasks;

        pse__Project_Task__c[] tOld = Database.query(theQuery);
        tOldMap = new Map<Id, pse__Project_Task__c> (tOld);

        tNew[0].pse__Start_Date_Time__c = DateTime.now();
        tNew[0].pse__End_Date_Time__c = DateTime.now().addDays(62);
        tNew[0].WorkTypeName__c = 'Field Office';
        tNew[0].IsWorkPlanTask__c = true;
        tNew[0].FinancialTask__c = false;
        tNew[0].isChargeable__c = false;

        ExpendItem__c exItem = new ExpendItem__c(PROJECTTASK__C = tNew[1].id,
                                                            EXPENDITURETYPE__C = 'CON-Subcontractor Exempt',
                                                            EXPENDITUREITEMDATE__C = Date.newInstance(2015, 05, 16),
                                                            CURRENCYISOCODE = 'NZD',
                                                            QUANTITY__C = 0,
                                                            VENDORID__C = '23456'
                                                            );
        insert exItem;
        CostDistLine__c cd1 = new CostDistLine__c(EXPENDITUREITEM__c = exItem.id,
                                                            PADATE__C = Date.newInstance(2016, 01, 23),
                                                            GLDATE__C = Date.newInstance(2016, 01, 12),
                                                            PROJECTRAWCOST__C = 23.5422,
                                                            PROJECTBURDENEDCOST__C = 28.71,
                                                            PROJECTFUNCTIONALRAWCOST__C = 23.5422,
                                                            PROJECTFUNCTIONALBURDENEDCOST__C = 28.71,
                                                            DENOMRAWCOST__C = 23.5422,
                                                            DENOMBURDENEDCOST__C = 28.71,
                                                            CURRENCYISOCODE = 'NZD',
                                                            PROJECTCURRENCYCODE__C = 'NZD',
                                                            ProjectFunctionalCurrencyCode__c = 'NZD',
                                                            DENOMCURRENCYCODE__C = 'NZD'
                                                            );
    }

    @isTest static void beforeInsert() {
        initData();

        tNew[1].ForecastStartDate__c = Date.today().addDays(1);
        tNew[1].ForecastEndDate__c = Date.today().addDays(30);
        // ECO_ProjectTaskService ets = new ECO_ProjectTaskService();
        ECO_ProjectTaskTriggers.setCurrencyISOCode(tNew);
        ECO_ProjectTaskTriggers.copyCarryingOutToTask(tNew); // not called in trigger...
        ECO_ProjectTaskTriggers.forecastSync(tNew, tOldMap , ets);
        ECO_ProjectTaskTriggers.applyLookups(tNew);
        ECO_ProjectTaskTriggers.calculateFiscalMonths(tNew);
        //tNew[1].TotalProjectFunctionalBurdenedCost__c=100.00;
        ECO_ProjectTaskTriggers.autoSetFinancialFlagsOnBeforeInsert(tNew);
        ECO_ProjectTaskTriggers.handleDefaultingTaskOwningCustomer(tNew);
        ECO_ProjectTaskTriggers.validateSyncedTasksOnInsert(tNew);
        //ECO_ProjectTaskTriggers.validateTaskNumbers(tNew, tOldMap);
        // ECO_ProjectTaskTriggers.forecastSync(tNew, tOldMap , ets);
    }

    @isTest static void beforeInsert1() {
        initData();
        
        test.Starttest();
        list<pse__Project_Task__c> lpTasks = new list<pse__Project_Task__c>();
        pse__Project_Task__c task = new pse__Project_Task__c();
            task.Name = 'task';
            task.pse__Project__c = tNew[0].pse__Project__c;
            task.pse__Start_Date_Time__c = DateTime.now().addDays(1);
            task.pse__End_Date_Time__c = DateTime.now().addDays(10);
            task.pse__Status__c = 'Draft';
            task.ProjectTaskNumber__c = 'tasknumber';
            task.pse__Description__c = 'task';
            task.WorkTypeName__c = 'Home Office';
            task.CostIndRateSCHID__c = '6748';
            task.pse__Parent_Task__c = tNew[0].Id;
            task.FinancialTask__c=true;
            lpTasks.add(task);
            try{
                insert lpTasks;
            }
            Catch(Exception e){

            }
            
        ECO_ProjectTaskTriggers.validateSyncedTasksOnInsert(lpTasks);
        //ECO_ProjectTaskTriggers.validateSyncedTasks(lpTasks,tOldMap);
        test.StopTest();
    }

    @isTest static void beforeInsertValidate() {
        initData();
        test.StartTest();
        // ECO_ProjectTaskTriggers.run = false;
        List<pse__Project_Task__c> lpTasks = [select id, pse__Project__c,pse__Start_Date__c, pse__End_Date__c,ForecastStartDate__c,ForecastEndDate__c from pse__Project_Task__c Where pse__Project__r.ORACLEPROJECTNUMBER__C = 'DPL201602090001' ];   

           // tNew.add(task);
            //tOldMap.put(task.Id, task);

            // ECO_ProjectTaskTriggers.run = true;
            lpTasks[0].pse__Parent_Task__c = tNew[1].Id;
            lpTasks[0].FinancialTask__c=true;
            //update lpTasks;
            //ECO_ProjectTaskTriggers.validateSyncedTasks(tNew,tOldMap);
        test.StopTest();

    }
    
    @isTest static void beforeUpdate() {
        initData();     
        test.startTest();
        ECO_ProjectTaskTriggers.validateReparent(tNew, tOldMap);
        ECO_ProjectTaskTriggers.validateFtAndWptTypeChange(tNew, tOldMap);  //Issue 4416, DJO 5/2016        
        ECO_ProjectTaskTriggers.autoSetFinancialFlagsOnBeforeUpdate(tNew);
        ECO_ProjectTaskTriggers.setChangeManagerIsChangedFlag(tNew);
        tNew[0].IsWorkPlanTask__c = false;
        ECO_ProjectTaskTriggers.setChangeManagerIsChangedFlag(tNew, true);
        tNew[0].IsWorkPlanTask__c = true;
        ECO_ProjectTaskTriggers.lockFieldsAfterOracleSync(tNew, tOldMap);
        tNew[0].OracleSyncStatus__c = 'T';
        ECO_ProjectTaskTriggers.lockFieldsAfterOracleSync(tNew, tOldMap);
        test.stopTest();
    }
    @isTest static void beforeUpdate1() {
        initData();
        tNew[0].pse__Parent_Task__c=tNew[1].Id;     
        ECO_ProjectTaskTriggers.validateReparent(tNew, tOldMap);
        
    }
        @isTest static void beforeUpdate2() {
        initData();
        tNew[0].ProjectTaskNumber__c='Testbeforeupdate';

        ECO_ProjectTaskTriggers.validateReparent(tNew, tOldMap);
    }
    
    @isTest static void beforeDelete() {
        initData();

        ECO_ProjectTaskTriggers.handleRemovingAssociatedFunding(tNew);
    }

    @isTest static void afters() {
        initData();       
        // tNew[0].ForecastStartDate__c = ;
        pse__Proj__c testProject = [SELECT Id, OUID__c FROM pse__Proj__c limit 1];
        List<pse__Project_Task__c> tasks1 = [select id, pse__Project__c,pse__Start_Date__c, pse__End_Date__c,ForecastStartDate__c,ForecastEndDate__c from pse__Project_Task__c Where pse__Project__r.ORACLEPROJECTNUMBER__C = 'DPL201602090001' ];
        System.debug('tasks1>>'+tasks1);
        Test.startTest();
        ECO_ProjectTaskTriggers.recalculateBudgets(tNew);
        //ECO_ProjectTaskTriggers.setProjectDates(tasks1); 
        ECO_ProjectTaskTriggers.calculateEarnedValueSnaps(tNew, tOldMap, ets);

        
        tNew[0].ForecastStartDate__c = Date.today().addDays(-5);

        ECO_ProjectTaskTriggers.rollupForecastDates( tNew, tOldMap, ets);


        ECO_ProjectTaskTriggers.replicateNewProjectTask(tNew);
        ECO_Service_RecordAccess.getProjectRecordAccess( tNew );

        ECO_ProjectTaskTriggers.legacyCalcsFromTriggerBody(false // trigger.isBefore
                                                            , false // trigger.IsInsert
                                                            , true //trigger.IsUpdate
                                                            , false // trigger.IsDelete
                                                            , true // trigger.IsAfter
                                                            , tNew
                                                            , tNew
                                                            , tOldMap, ets);

        tNew[0].IsChargeable__c = true;
        tNew[0].IsWorkPlanTask__c = false;
        tNew[0].FinancialTask__c = true;

        ECO_ProjectTaskTriggers.replicateNewProjectTask(tNew);

        ECO_ProjectTaskTriggers.legacyCalcsFromTriggerBody(false // trigger.isBefore
                                                            , false // trigger.IsInsert
                                                            , true //trigger.IsUpdate
                                                            , false // trigger.IsDelete
                                                            , true // trigger.IsAfter
                                                            , tNew
                                                            , tNew
                                                            , tOldMap, ets);
    Test.stopTest();
        // ECO_ProjectTaskTriggers.recalculateProjects(new Set<Id> { tNew[0].pse__Project__c }, true);
        // ECO_ProjectTaskTriggers.recalculateProjectDates(tNew); // not called in trigger...
    }

    @isTest static void afterDelete() {


        initData();
        tNew[0].ForecastStartDate__c = Date.today().addDays(-5);

        ECO_ProjectTaskTriggers.rollupForecastDatesDelete(tOldMap, ets);
        // ECO_ProjectTaskValidator.validateForDelete(tNew);

        ECO_ProjectTaskTriggers.legacyCalcsFromTriggerBody(false // trigger.isBefore
                                                            , false // trigger.IsInsert
                                                            , false //trigger.IsUpdate
                                                            , true // trigger.IsDelete
                                                            , true // trigger.IsAfter
                                                            , tNew
                                                            , tNew
                                                            , tOldMap, ets);
    }

    @isTest static void eco_pseTriggers() {
        
        Test.startTest();
        System.Debug(Limits.getLimitQueries());
        Boolean testBool = ECO_pseProjectTaskTriggers.isGanttSaveInProcess();
        ECO_pseProjectTaskTriggers pse = new ECO_pseProjectTaskTriggers();
        ECO_pseProjectTaskTriggers.handler();

        
        ECO_pseProjectTaskTriggers.externalTriggerStart();
        ECO_pseProjectTaskTriggers.externalTriggerFinish();
        Test.stopTest();
    }

    @isTest static void runAllFalse() {
        initData();

        // ECO_ProjectTaskTest

        Test.startTest();
        System.Debug(Limits.getLimitQueries());
        ECO_ProjectTask.init(tOldMap);
        Boolean testisSyncedWithOracle = ECO_ProjectTaskTriggers.isSyncedWithOracle('T');
        testisSyncedWithOracle = ECO_ProjectTaskTriggers.isSyncedWithOracle(null);
        ECO_ProjectTaskTriggers.run = false;
        ECO_ProjectTriggers.run = false;

        // Before Insert
        ECO_ProjectTaskTriggers.setCurrencyISOCode(tNew);
        ECO_ProjectTaskTriggers.forecastSync(tNew, tOldMap , ets);
        ECO_ProjectTaskTriggers.applyLookups(tNew);
        ECO_ProjectTaskTriggers.calculateFiscalMonths(tNew);
        ECO_ProjectTaskTriggers.autoSetFinancialFlagsOnBeforeInsert(tNew);
        ECO_ProjectTaskTriggers.handleDefaultingTaskOwningCustomer(tNew);
        ECO_ProjectTaskTriggers.validateSyncedTasksOnInsert(tNew);

        // beforeUpdate
        ECO_ProjectTaskTriggers.validateReparent(tNew, tOldMap);
        ECO_ProjectTaskTriggers.validateFtAndWptTypeChange(tNew, tOldMap);  //Issue 4416, DJO 5/2016        
        ECO_ProjectTaskTriggers.autoSetFinancialFlagsOnBeforeUpdate(tNew);
        ECO_ProjectTaskTriggers.setChangeManagerIsChangedFlag(tNew);
        ECO_ProjectTaskTriggers.setChangeManagerIsChangedFlag(tNew, true);
        ECO_ProjectTaskTriggers.lockFieldsAfterOracleSync(tNew, tOldMap);
        ECO_ProjectTaskTriggers.lockFieldsAfterOracleSync(tNew, tOldMap);
        ECO_ProjectTaskTriggers.recalculateBudgets(tNew);
        ECO_ProjectTaskTriggers.setProjectDates(tNew); 
        ECO_ProjectTaskTriggers.calculateEarnedValueSnaps(tNew, tOldMap, ets);

        // afters
        ECO_ProjectTaskTriggers.recalculateBudgets(tNew);
        ECO_ProjectTaskTriggers.setProjectDates(tNew); 
        ECO_ProjectTaskTriggers.calculateEarnedValueSnaps(tNew, tOldMap, ets);

        ECO_ProjectTaskTriggers.replicateNewProjectTask(tNew);
        ECO_ProjectTaskTriggers.rollupForecastDates( tNew, tOldMap, ets);
        ECO_ProjectTaskTriggers.copyCarryingOutToTask(tNew);
        ECO_ProjectTaskTriggers.copyingCarrying = false;
        ECO_ProjectTaskTriggers.copyCarryingOutToTask(tNew);
        ECO_ProjectTaskTriggers.rollupForecastDatesDelete(tOldMap, ets);
        ECO_ProjectTaskTriggers.validateCanDeleteTasks(tNew);
        ECO_ProjectTaskTriggers.oldApplyLookups(tNew, ets);
        ECO_ProjectTaskTriggers.getReferenceMap();
 
        ECO_ProjectTaskTriggers.legacyCalcsFromTriggerBody(false // trigger.isBefore
                                                            , false // trigger.IsInsert
                                                            , true //trigger.IsUpdate
                                                            , false // trigger.IsDelete
                                                            , true // trigger.IsAfter
                                                            , tNew
                                                            , tNew
                                                            , tOldMap, ets);
        Test.stopTest();
    }
}
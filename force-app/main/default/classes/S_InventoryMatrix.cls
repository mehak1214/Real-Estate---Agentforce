/*
** ____________________________________________________________________________________________
** Created by	:   Akash Pawar
** Created Date	:   00/11/2020 
** Company Name	: 	Stetig Consulting Pvt Ltd
** ============================================================================================
** Description	: 	controller for inventory matrix
** ____________________________________________________________________________________________
*/

public with sharing class S_InventoryMatrix {
    
    public Product2 unit {
        get;
        private set;
    }
    public String selectedTower {
        get; 
        set;
    }
    public String selectedVal {
        get;
        set;
    }
    public String selectedFloor {
        get;
        set;
    }
    public String selectedFloorBand {
        get;
        set;
    }
    public String selectedstatus {
        get;
        set;
    }
    public String SelectedClusterId {
        get;
        set;
    }
    public String SelectedProjectId {
        get;
        set;
    }
    public String selectedConf {
        get;
        set;
    }
    public Boolean sold {
        get;
        set;
    }
    public Boolean open {
        get;
        set;
    }
    public Boolean booked {
        get;
        set;
    }
    public Boolean blocked {
        get;
        set;
    }
    public Boolean reserved {
        get;
        set;
    }
    public Boolean onebhk {
        get;
        set;
    }
    public Boolean twobhk {
        get;
        set;
    }
    public Boolean threebhk {
        get;
        set;
    }
    public Boolean fourbhk {
        get;
        set;
    }
    public Boolean fivebhk {
        get;
        set;
    }
    public List < Decimal > floorAscSeqList {
        get;
        set;
    }
    public Map < Decimal, List < Product2 >> JMap {
        get;
        set;
    }
    public string SelectedProjectOpty {
        get;
        set;
    }
    public string serialiseString{get;set;}
    public string ssString{get;set;}
    public string sTowerString{get;set;}
    
    
    
    public  boolean isRendered {get; set;}
    public String UserWorkingOnProject {get;set;}
    
    public  Map<String ,Decimal> statusWiseCountMap {get;set;}
    public decimal totalofunit {get;set;} 
    
    public String OptyID {get;set;}
    
    public string ProdId {get;set;} 
    
    public string DirectURL {get;set;} 
    
    public boolean displayPopup1 {get; set;}
    
    public string callfunc{get;set;}
    
    public boolean alertFlag{get; set;}
    
    public boolean ShowPercentage{get; set;}
    
    public string Block{get; set;}
    
    public AnalyticChart ac {get;set;}
    public list<AnalyticChart> acList{get;set;}
    
    List < Project__c > queryResult = new List < Project__c > ();
    
    public integer To_be_Released{get; set;}
    public integer Available_for_Sale{get; set;}
    public integer Blocked_by_Mgmt{get; set;}
    public integer Blocked_by_Sales_Head{get; set;}
    public integer Refuge{get; set;}
    public integer Sold_status{get; set;}
    public integer Cancellation_Available_for_Use{get; set;}
    public integer Under_Cancellation{get; set;}
    public integer Hold{get; set;}
    public integer Total{get; set;}
    
    public Double To_be_ReleasedD{get; set;}
    public Double Available_for_SaleD{get; set;}
    public Double Blocked_by_MgmtD{get; set;}
    public Double Blocked_by_Sales_HeadD{get; set;}
    public Double RefugeD{get; set;}
    public Double Sold_statusD{get; set;}
    public Double Cancellation_Available_for_UseD{get; set;}
    public Double Under_CancellationD{get; set;}
    public Double HoldD{get; set;}
    
    public Double To_be_Releasedsqft{get; set;}
    public Double Available_for_Salesqft{get; set;}
    public Double Blocked_by_Mgmtsqft{get; set;}
    public Double Blocked_by_Sales_Headsqft{get; set;}
    public Double Refugesqft{get; set;}
    public Double Sold_statussqft{get; set;}
    public Double Cancellation_Available_for_Usesqft{get; set;}
    public Double Under_Cancellationsqft{get; set;}
    public Double Holdsqft{get; set;}
    
    public Double To_be_Releasedsqm{get; set;}
    public Double Available_for_Salesqm{get; set;}
    public Double Blocked_by_Mgmtsqm{get; set;}
    public Double Blocked_by_Sales_Headsqm{get; set;}
    public Double Refugesqm{get; set;}
    public Double Sold_statussqm{get; set;}
    public Double Cancellation_Available_for_Usesqm{get; set;}
    public Double Under_Cancellationsqm{get; set;}
    public Double Holdsqm{get; set;}
    
    public Integer totalUnit{get;set;}
    public Double totalsqft{get;set;}
    public Double totalsqmt{get;set;}
    
    public Integer totalOpen{get;set;}
    public Integer totalBlocked{get;set;}
    public Integer totalSold{get;set;}
    
    Public CategoryUnit Haven{get;set;} 
    Public CategoryUnit Nest{get;set;} 	
    
    
    String projectsent = ApexPages.currentPage().getParameters().get('projectsent');
    String statussent = ApexPages.currentPage().getParameters().get('statussent');
    String towersent = ApexPages.currentPage().getParameters().get('towersent');
    String FloorBand = ApexPages.currentPage().getParameters().get('FloorBand');
    String Floor = ApexPages.currentPage().getParameters().get('Floor');
    
    String projectsent1 = '';
    String towersent1 = '';
    
    List < String > s = new List < String > ();    
    
    public string  width{
        get;
        set;
    }
    
    public void show(){
        isRendered = true;
        system.debug('show() :: isRendered :: '+isRendered);
    }
    
    public void hide(){
        isRendered = false;
        system.debug('hide() :: isRendered :: '+isRendered);
    }
    
    public integer Haven_open_1_to_10{get;set;}
    public integer Haven_open_11_to_20{get;set;}
    public integer Haven_open_21_to_30{get;set;}
    public integer Haven_open_31_plus{get;set;}
    public integer Haven_Total_Open{get;set;}
    
    public   integer Haven_Sold_1_to_10{get;set;}
    public integer Haven_Sold_11_to_20{get;set;}
    public integer Haven_Sold_21_to_30{get;set;}
    public integer Haven_Sold_31_plus{get;set;}
    public integer Haven_Sold_Open{get;set;}
    
    public  integer Haven_NA_1_to_10{get;set;}
    public  integer Haven_NA_11_to_20{get;set;}
    public  integer Haven_NA_21_to_30{get;set;}
    public  integer Haven_NA_31_plus{get;set;}
    public  integer Haven_NA_Open{get;set;}
    
    public   integer Nest_open_1_to_10{get;set;}
    public   integer Nest_open_11_to_20{get;set;}
    public   integer Nest_open_21_to_30{get;set;}
    public   integer Nest_open_31_plus{get;set;}
    public   integer Nest_Total_Open{get;set;}
    
    public  integer Nest_Sold_1_to_10{get;set;}
    public  integer Nest_Sold_11_to_20{get;set;}
    public  integer Nest_Sold_21_to_30{get;set;}
    public  integer Nest_Sold_31_plus{get;set;}
    public  integer Nest_Sold_Open{get;set;}
    
    public   integer Nest_NA_1_to_10{get;set;}
    public   integer Nest_NA_11_to_20{get;set;}
    public   integer Nest_NA_21_to_30{get;set;}
    public   integer Nest_NA_31_plus{get;set;}
    public  integer Nest_NA_Open{get;set;}
    
    public List<product2> UnitListForDashboard{get;set;}
    
    public S_InventoryMatrix () {
        isRendered = false;
        serialiseString = '';
        ssString = '';
        width = 'width:1200px;';
        ac= new AnalyticChart();
        acList = new List<AnalyticChart>();
        ac.column='Product2.Project__c';
        ac.operator = 'equals';
        ac.value = NULL;
        acList.add(ac);
        serialiseString = JSON.serialize(acList) ;
        acList = new List<AnalyticChart>();
        // ShowDashboardStr = 'Show Dashboard';
        statusWiseCountMap = new Map <string, Decimal>();
        totalofunit = 0;
        To_be_Released = 0;
        Available_for_Sale= 0;
        Blocked_by_Mgmt= 0;
        Blocked_by_Sales_Head= 0;
        Refuge= 0;
        Sold_status= 0;
        Cancellation_Available_for_Use= 0;
        Under_Cancellation= 0;
        Hold= 0;
        Total = 0;
        
        To_be_ReleasedD = 0;
        Available_for_SaleD = 0;
        Blocked_by_MgmtD = 0;
        Blocked_by_Sales_HeadD = 0;
        RefugeD = 0;
        Sold_statusD = 0;
        Cancellation_Available_for_UseD = 0;
        Under_CancellationD = 0;
        HoldD = 0;
        
        To_be_Releasedsqft = 0;
        Available_for_Salesqft= 0;
        Blocked_by_Mgmtsqft= 0;
        Blocked_by_Sales_Headsqft= 0;
        Refugesqft= 0;
        Sold_statussqft= 0;
        Cancellation_Available_for_Usesqft= 0;
        Under_Cancellationsqft= 0;
        Holdsqft= 0;
        
        To_be_Releasedsqm = 0;
        Available_for_Salesqm= 0;
        Blocked_by_Mgmtsqm= 0;
        Blocked_by_Sales_Headsqm= 0;
        Refugesqm= 0;
        Sold_statussqm= 0;
        Cancellation_Available_for_Usesqm= 0;
        Under_Cancellationsqm= 0;
        Holdsqm = 0;        
        
        Haven_open_1_to_10 = 0;
        Haven_open_11_to_20 = 0;
        Haven_open_21_to_30=0;
        Haven_open_31_plus = 0;
        Haven_Total_Open=0;
        
        Haven_Sold_1_to_10=0;
        Haven_Sold_11_to_20 = 0;
        Haven_Sold_21_to_30=0;
        Haven_Sold_31_plus=0;
        Haven_Sold_Open=0;
        
        Haven_NA_1_to_10=0;
        Haven_NA_11_to_20=0;
        Haven_NA_21_to_30=0;
        Haven_NA_31_plus=0;
        Haven_NA_Open=0;
        
        Nest_open_1_to_10 = 0;
        Nest_open_11_to_20=0;
        Nest_open_21_to_30 = 0;
        Nest_open_31_plus= 0;
        Nest_Total_Open=0;
        
        Nest_Sold_1_to_10=0;
        Nest_Sold_11_to_20 = 0;
        Nest_Sold_21_to_30 = 0;
        Nest_Sold_31_plus = 0;
        Nest_Sold_Open = 0;
        
        Nest_NA_1_to_10 = 0;
        Nest_NA_11_to_20 = 0;
        Nest_NA_21_to_30 = 0;
        Nest_NA_31_plus = 0;
        Nest_NA_Open = 0;
        
        UnitListForDashboard =  new List<product2>();
        
        Nest = new CategoryUnit();
        Haven = new CategoryUnit();
        // UserWorkingOnProject = [select Working_in_Project__c from User where Id =:UserInfo.getUserId()][0].Working_in_Project__c ;
        system.debug('UserWorkingOnProject:' + UserWorkingOnProject );
        // UserWorkingOnProject = getAllProject()[0];
        SelectedProjectOpty = ApexPages.currentPage().getParameters().get('optyProject');
        system.debug('SelectedProjectOpty:' + SelectedProjectOpty );
        
        OptyID = ApexPages.currentPage().getParameters().get('OptyID');
        system.debug('OptyID---------:' + OptyID );
        
        // if( (alertFlag != true || alertFlag== NULL) && ApexPages.currentPage().getParameters().get('block') != NULL ){
        // Block =ApexPages.currentPage().getParameters().get('block');
        /*if(alertFlag == NULL || alertFlag == false){
alertFlag = true;
callfunc='<script> showToast(\'' +'Test'+ '\'); </script>';
system.debug('inside callfunc'+Block);
}else{
alertFlag = false;
}*/
        //}else{
        //   alertFlag = false;
        //}
        DirectURL = 'window.open(\'/apex/MyCustomLookup?pid=\',\'_blank\',\'height=400,location=no,resizable=yes,toolbar=no,status=no,menubar=no,scrollbars=1\', 1)';
    }
    
    public List < SelectOption > getProjects {
        get {
            system.debug('getProjectInsideMethod:' );
            
            List < SelectOption > optns = new List < Selectoption > ();
            //List < Project__c > queryResult = new List < Project__c > ();
            
            //if(SelectedProjectOpty != null) {
            system.debug('inside if getProjectInsideMethod:' );
            queryResult = [select Id, Name from Project__c where Active__c = true ];
            system.debug('queryResult---'+queryResult);
            // selectedVal = SelectedProjectOpty;
            //system.debug('selectedVal:' + selectedVal );
            // }
            /* else if(UserWorkingOnProject != null){

Set <String> strPrjName = new Set <String>();
String[] StrUserSelectedprj = UserWorkingOnProject.split(';');

for(String str : StrUserSelectedprj ){
strPrjName.add(str);
}
if(!strPrjName.isEmpty()){
queryResult = [Select Id, Name from Project__c where Name IN : strPrjName];
}
}*/
            optns.add(new SelectOption('', 'Select a Project'));
            for (Project__c obj: queryResult) {
                optns.add(new SelectOption(obj.Id, obj.Name));
            }
            return optns;
        }
        set;
    }
    /*
public List < SelectOption > getClusterNames {

get {

set < string > clusterSet = new set < string > ();
List < SelectOption > ClusterOptions = new List < SelectOption > ();
ClusterOptions.add(new SelectOption('0', 'Select a Phase'));
if (selectedVal != null) {
for (Cluster__c c: [select Id, name, Project__c from Cluster__c Where Project__c = : selectedVal]) {
if (!clusterSet.contains(c.name.tolowercase())) {
ClusterOptions.add(new SelectOption(c.Id, c.name));
}
clusterSet.add(c.name.tolowercase());
}
}
return ClusterOptions;
}
set;

}
*/
    
    public List < SelectOption > getTowers {
        
        get {
            List < SelectOption > options = new List < Selectoption > ();
            options.add(new SelectOption('', 'Select a Tower'));
            getFloorBands = new List<SelectOption>();
            getFloorBands.add(new SelectOption('', 'Select a Floor Band'));
            system.debug('SelectedProjectOpty--'+SelectedProjectOpty);
            if (selectedVal != null) { 
                //isRendered = true;
                List < Tower__c > qResult = new List < Tower__c > ([Select Id, Name,Project__c, Project__r.name from Tower__c where Project__c = : selectedVal  order by Name asc]);
                system.debug('Tower qResult--'+qResult);
                
                for (Tower__c obj1: qResult) {
                    options.add(new SelectOption(obj1.Id, obj1.Name));
                }
                ShowPercentage = true;
                
            }
            //system.debug('options'+options[0].);
            system.debug('serialiseString'+serialiseString);
            return options;
        }
        set;
    }
    public List < SelectOption > getFloorBands {
        get {
            List < SelectOption > FloorBands_options = new List < Selectoption > ();
            FloorBands_options.add(new SelectOption('', 'Select a Floor Band'));
            system.debug('selectedTower'+selectedTower);
            if(towersent != selectedTower || projectsent != selectedVal){
            }else if (selectedTower != null ) {
                List < Product2 > unitlist = new List < Product2 >();
                unitlist = ([SELECT Id,Name, Floor_No__c ,Unit_Status__c,Unit_Category__c,Tower__r.Name, Tower__c,Project__r.Name,
                             Project__c,Carpet_Area_RERA_Carpet__c, Saleable_Area__c,  Opportunity__c,type_of_unit_by_size__c from Product2 where Tower__c = : selectedTower AND Family = 'Saleable Unit' order by Floor_No__c DESC]); 
                system.debug('err at ---');
                if(unitlist.size() != 0){
                    
                    Decimal FloorNo = decimal.valueof( unitlist[0].Floor_No__c);
                    Integer Floor_No = FloorNo.intValue();
                    system.debug('Floor_No---'+Floor_No);
                    Integer rem = Math.Mod(Floor_No, 10	);
                    system.debug('rem---'+rem);
                    Integer Div = 0;
                    if(rem == 0 || Floor_No ==0){
                        Div = Floor_No/10;
                        system.debug('if Div---'+Div);
                    }else{
                        Div = Floor_No/10 + 1;
                        system.debug('else Div---'+Div);
                    } 
                    
                    Decimal S = 1; Decimal E = 10;
                    String FloorBand = '';
                    while(Div!=0){
                        FloorBand = String.valueOf(S)+ ' - ' + String.valueOf(E) + ' Floor';
                        system.debug('new_Div---'+Div);
                        system.debug('FloorBand---'+FloorBand);
                        FloorBands_options.add(new SelectOption(FloorBand, FloorBand));
                        S=S+10; E=E+10;
                        Div = Div-1;
                    }   
                }
            }
            system.debug('FloorBands_options :: '+FloorBands_options);
            return FloorBands_options;
        }
        set;
    }
    
    
    public string getfilter {
        get {
            string fil;
            list<Tower__c> TowerList = new list<Tower__c>();
            ac= new AnalyticChart();
            acList = new List<AnalyticChart>();
            ac.column='Product2.Project__c';
            ac.operator = 'equals';
            ac.value = 'NULL454654856';
            AnalyticChart actower= new AnalyticChart();
            actower.column='FK_CUSTENT_ID';
            actower.operator = 'equals';
            actower.value = 'NULL12345678915';
            system.debug('selectedVal :: '+selectedVal);
            if(selectedVal != NULL){
                list<Project__c> pro = new list<Project__c>([select name from Project__c where id =: selectedVal]); 
                if(pro != NULL && !pro.isEmpty()){
                    ac.value = pro[0].Name;
                    if (selectedTower != null) {
                        TowerList = [select Id,name from Tower__c where id =: selectedTower AND Project__c =: selectedVal]; 
                        if(TowerList != NULL && !TowerList.isEmpty()){
                            actower.column='FK_CUSTENT_ID';
                            actower.operator = 'equals';
                            actower.value = TowerList[0].Id;
                        }
                    }
                }
            }
            acList.add(ac);
            if(selectedTower != NULL){
                acList.add(actower);
            }
            fil = JSON.serialize(acList) ;
            return fil;
        }
        set;
    }
    
    
    public List < SelectOption > getFloor {
        
        get {
            List < SelectOption > floor_options = new List < Selectoption > ();
            floor_options.add(new SelectOption('', 'Select a Floor'));
            if (selectedFloorBand != null) {
                system.debug('selectedFloorBand=---'+selectedFloorBand);
                String d = selectedFloorBand.substringBefore(' -');
                String E = selectedFloorBand.substringBetween('- ', ' Floor');
                system.debug('d'+d);
                system.debug('E'+E);
                Integer Start = Integer.valueOf(d);
                Integer EndF = Integer.valueOf(E);
                while(start <= EndF){
                    String S = String.valueOf(start);
                    floor_options.add(new SelectOption(S,S));
                    start = start + 1;
                }  
            }
            return floor_options;
        }
        set;
    }
    
    
    public boolean isRend {
        get {
            system.debug('isRendered'+isRendered);
            return isRendered;
        }
        set;
    }
    
    public String  ChkMapKey {get;set;}
    
    public List < Decimal > floorDescSeqList {
        get {
            system.debug('selectedTower:' + selectedTower);
            system.debug('selectedVal:' + selectedVal);
            system.debug('selectedFloorBand:' + selectedFloorBand);
            system.debug('selectedFloor:' + selectedFloor);
            if(towersent != selectedTower){
                FloorBand = null;
            }else{
                
                FloorBand = selectedFloorBand;
            }
            towersent = selectedTower;
            projectsent = selectedVal;
            
            Floor = selectedFloor;
            
            JMap = new Map < Decimal, List < Product2 >> ();
            floorAscSeqList = new List < Decimal > ();
            floorDescSeqList = new List < Decimal > ();
            system.debug('towersent ..' + towersent);
            system.debug('projectsent ..' + projectsent);
            system.debug('FloorBand ..' + FloorBand);
            system.debug('Floor ..' + Floor);
            //statusWiseCountMap = new Map<String,Decimal>();
            statusWiseCountMap.clear();
            totalofunit = 0;
            Integer statuscount =0;
            Set <ID> UnitID = new set <ID>();
            List < Product2 > unitlist = new List < Product2 >();
            if (towersent != null && projectsent != null && FloorBand == null && Floor == null) {
                
                unitlist = 
                    ([select Id,Name,Appt__c,IsActive,Facets__c,Floor_No__c,Family,Project__c,Tower__c,Tower__r.Name,Unit_Category__c,Unit_Status__c,Saleable_Area__c,Carpet_Area_RERA_Carpet__c,type_of_unit_by_size__c,Floor_Band__c  from Product2 
                      where Tower__c = : towersent AND IsActive=true AND Family='Saleable Unit'  order by Floor_No__c DESC, Name ASC, Appt__c]);           
                
                // UnitListForDashboard =  new List<product2>();
                //  UnitListForDashboard = unitlist;
                System.debug('UNIT LIST:' + unitList);
                system.debug('Unit list size : '+unitList.size());
            }
            if (towersent != null && projectsent != null && FloorBand != null && Floor == null) {
                String d = selectedFloorBand.substringBefore(' -');
                String E = selectedFloorBand.substringBetween('- ', ' Floor');
                system.debug('d'+d);
                system.debug('E'+E);
                Integer Start = Integer.valueOf(d);
                Integer EndF = Integer.valueOf(E);
                list<String> FloorsList = new list<String>();
                integer i;
                for(i=Start;i<=EndF;i++){
                    FloorsList.add(string.valueOf(i));
                }
                unitlist = ([SELECT Id , Name, Floor_No__c ,Unit_Status__c,Unit_Category__c,Appt__c,
                             Project__c,Carpet_Area_RERA_Carpet__c, Saleable_Area__c, /*Unit_Name__c,*/ Opportunity__c/*, Payable_Within__c*/,Tower__r.Name,type_of_unit_by_size__c,Floor_Band__c
                             from Product2 where Tower__c = : towersent AND  Family = 'Saleable Unit'  AND  Floor_No__c IN: FloorsList/*
Integer.valueof(Floor_No__c) >=: Start AND integer.valueof(Floor_No__c) <=: EndF*/ order by Floor_No__c DESC, Name ASC]); 
                System.debug('UNIT LIST:' + unitList);  
                system.debug('Unit list size : '+unitList.size());
            }
            if (towersent != null && projectsent != null && FloorBand != null && Floor != null) {
                Decimal FloorNo = Decimal.valueOf(Floor);
                unitlist = ([SELECT Id /*, Unit_No__c */, Floor_No__c , Unit_Status__c/*, Unit_Floor__c*/, Name, Carpet_Area_RERA_Carpet__c,Unit_Category__c,Appt__c,type_of_unit_by_size__c,Floor_Band__c,
                             Project__c,  Saleable_Area__c, /*Unit_Name__c,*/ Opportunity__c/*, Payable_Within__c*/,Tower__r.Name
                             from Product2 where Tower__c = : towersent  AND Family = 'Saleable Unit' /*AND Floor_No__c =: string.valueOf(FloorNo) */ order by Floor_No__c DESC, Name ASC]); 
                System.debug('UNIT LIST:' + unitList);
                system.debug('Unit list size : '+unitList.size());
                
            }
            //unit map create
            To_be_Released = 0;
            Available_for_Sale= 0;
            Blocked_by_Mgmt= 0;
            Blocked_by_Sales_Head= 0;
            Refuge= 0;	
            Sold_status= 0;
            Cancellation_Available_for_Use= 0;
            Under_Cancellation= 0;
            Hold= 0;
            Total = 0;
            
            To_be_ReleasedD = 0;
            Available_for_SaleD = 0;
            Blocked_by_MgmtD = 0;
            Blocked_by_Sales_HeadD = 0;
            RefugeD = 0;
            Sold_statusD = 0;
            Cancellation_Available_for_UseD = 0;
            Under_CancellationD = 0;
            HoldD = 0;
            
            To_be_Releasedsqft = 0;
            Available_for_Salesqft= 0;
            Blocked_by_Mgmtsqft= 0;
            Blocked_by_Sales_Headsqft= 0;
            Refugesqft= 0;
            Sold_statussqft= 0;
            Cancellation_Available_for_Usesqft= 0;
            Under_Cancellationsqft= 0;
            Holdsqft= 0;
            
            To_be_Releasedsqm = 0;
            Available_for_Salesqm= 0;
            Blocked_by_Mgmtsqm= 0;
            Blocked_by_Sales_Headsqm= 0;
            Refugesqm= 0;
            Sold_statussqm= 0;
            Cancellation_Available_for_Usesqm= 0;
            Under_Cancellationsqm= 0;
            Holdsqm = 0;      
            
            totalUnit = 0;
            totalsqft = 0;
            totalsqmt = 0;
            
            totalOpen = 0;
            totalBlocked = 0;
            totalSold = 0;
            
            Haven_open_1_to_10 = 0;
            Haven_open_11_to_20 = 0;
            Haven_open_21_to_30=0;
            Haven_open_31_plus = 0;
            Haven_Total_Open=0;
            
            Haven_Sold_1_to_10=0;
            Haven_Sold_11_to_20 = 0;
            Haven_Sold_21_to_30=0;
            Haven_Sold_31_plus=0;
            Haven_Sold_Open=0;
            
            Haven_NA_1_to_10=0;
            Haven_NA_11_to_20=0;
            Haven_NA_21_to_30=0;
            Haven_NA_31_plus=0;
            Haven_NA_Open=0;
            
            Nest_open_1_to_10 = 0;
            Nest_open_11_to_20=0;
            Nest_open_21_to_30 = 0;
            Nest_open_31_plus= 0;
            Nest_Total_Open=0;
            
            Nest_Sold_1_to_10=0;
            Nest_Sold_11_to_20 = 0;
            Nest_Sold_21_to_30 = 0;
            Nest_Sold_31_plus = 0;
            Nest_Sold_Open = 0;
            
            Nest_NA_1_to_10 = 0;
            Nest_NA_11_to_20 = 0;
            Nest_NA_21_to_30 = 0;
            Nest_NA_31_plus = 0;
            Nest_NA_Open = 0;
            
            Integer Sizeofblock = 0;
            if(unitlist.size() != 0){
                
                /* UnitListForDashboard = 
([select Id,Name,Appt__c,IsActive,Facets__c,Floor_No__c,Family,Project__c,Tower__c,Tower__r.Name,Unit_Category__c,Unit_Status__c,Saleable_Area__c,Carpet_Area_RERA_Carpet__c,type_of_unit_by_size__c,Floor_Band__c  from Product2 
where Tower__c = : towersent AND IsActive=true AND Family='Saleable Unit'  order by Floor_No__c DESC, Name ASC, Appt__c]);           
*/
                
                for (Product2 thisUnit: unitlist) 
                {
                    if(thisUnit.Unit_Status__c == 'To be Released'){
                        To_be_Released = To_be_Released + 1;
                        To_be_Releasedsqft = To_be_Releasedsqft+ thisUnit.Carpet_Area_RERA_Carpet__c;
                        if(thisUnit.type_of_unit_by_size__c == 'Haven'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Haven_NA_1_to_10  = Haven_NA_1_to_10+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Haven_NA_11_to_20 = Haven_NA_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Haven_NA_21_to_30 = Haven_NA_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Haven_NA_31_plus = Haven_NA_31_plus + 1; 
                            }
                        }
                        else if(thisUnit.type_of_unit_by_size__c == 'Nest'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Nest_NA_1_to_10  = Nest_NA_1_to_10 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Nest_NA_11_to_20  = Nest_NA_11_to_20 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Nest_NA_21_to_30  = Nest_NA_21_to_30  + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Nest_NA_31_plus  = Nest_NA_31_plus  + 1; 
                            }
                        }
                    }
                    
                    if(thisUnit.Unit_Status__c == 'Available for Sale'){
                        Available_for_Sale = Available_for_Sale + 1;
                        Available_for_Salesqft = Available_for_Salesqft+ thisUnit.Carpet_Area_RERA_Carpet__c;
                        if(thisUnit.type_of_unit_by_size__c == 'Haven'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Haven_open_1_to_10  = Haven_open_1_to_10 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Haven_open_11_to_20 =  Haven_open_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Haven_open_21_to_30 = Haven_open_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Haven_open_31_plus = Haven_open_31_plus + 1; 
                            }
                        }
                        else if(thisUnit.type_of_unit_by_size__c == 'Nest'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Nest_open_1_to_10 =  Nest_open_1_to_10+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Nest_open_11_to_20 = Nest_open_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Nest_open_21_to_30 = Nest_open_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Nest_open_31_plus = Nest_open_31_plus + 1; 
                            }
                        }
                    }
                    if(thisUnit.Unit_Status__c == 'Blocked by Mgmt'){
                        Blocked_by_Mgmt= Blocked_by_Mgmt+ 1;
                        Blocked_by_Mgmtsqft = Blocked_by_Mgmtsqft+ thisUnit.Carpet_Area_RERA_Carpet__c;
                        if(thisUnit.type_of_unit_by_size__c == 'Haven'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Haven_NA_1_to_10  = Haven_NA_1_to_10+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Haven_NA_11_to_20 = Haven_NA_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Haven_NA_21_to_30 = Haven_NA_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Haven_NA_31_plus = Haven_NA_31_plus + 1; 
                            }
                        }
                        else if(thisUnit.type_of_unit_by_size__c == 'Nest'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Nest_NA_1_to_10  = Nest_NA_1_to_10 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Nest_NA_11_to_20  = Nest_NA_11_to_20 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Nest_NA_21_to_30  = Nest_NA_21_to_30  + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Nest_NA_31_plus  = Nest_NA_31_plus  + 1; 
                            }
                        }
                    }
                    if(thisUnit.Unit_Status__c == 'Blocked by Sales Head'){
                        Blocked_by_Sales_Head= Blocked_by_Sales_Head+ 1;
                        Blocked_by_Sales_Headsqft = Blocked_by_Sales_Headsqft+ thisUnit.Carpet_Area_RERA_Carpet__c;
                        if(thisUnit.type_of_unit_by_size__c == 'Haven'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Haven_NA_1_to_10  = Haven_NA_1_to_10+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Haven_NA_11_to_20 = Haven_NA_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Haven_NA_21_to_30 = Haven_NA_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Haven_NA_31_plus = Haven_NA_31_plus + 1; 
                            }
                        }
                        else if(thisUnit.type_of_unit_by_size__c == 'Nest'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Nest_NA_1_to_10  = Nest_NA_1_to_10 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Nest_NA_11_to_20  = Nest_NA_11_to_20 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Nest_NA_21_to_30  = Nest_NA_21_to_30  + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Nest_NA_31_plus  = Nest_NA_31_plus  + 1; 
                            }
                        }
                    }
                    if(thisUnit.Unit_Status__c == 'Refuge'){
                        Refuge= Refuge+ 1;
                        Refugesqft = Refugesqft+ thisUnit.Carpet_Area_RERA_Carpet__c;
                        if(thisUnit.type_of_unit_by_size__c == 'Haven'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Haven_NA_1_to_10  = Haven_NA_1_to_10+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Haven_NA_11_to_20 = Haven_NA_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Haven_NA_21_to_30 = Haven_NA_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Haven_NA_31_plus = Haven_NA_31_plus + 1; 
                            }
                        }
                        else if(thisUnit.type_of_unit_by_size__c == 'Nest'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Nest_NA_1_to_10  = Nest_NA_1_to_10 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Nest_NA_11_to_20  = Nest_NA_11_to_20 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Nest_NA_21_to_30  = Nest_NA_21_to_30  + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Nest_NA_31_plus  = Nest_NA_31_plus  + 1; 
                            }
                        }
                    }
                    if(thisUnit.Unit_Status__c == 'Sold'){
                        Sold_status= Sold_status+ 1;
                        Sold_statussqft = Sold_statussqft+ thisUnit.Carpet_Area_RERA_Carpet__c;
                        if(thisUnit.type_of_unit_by_size__c == 'Haven'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Haven_Sold_1_to_10 = Haven_Sold_1_to_10+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Haven_Sold_11_to_20 = Haven_Sold_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Haven_Sold_21_to_30 = Haven_Sold_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Haven_Sold_31_plus = Haven_Sold_31_plus + 1; 
                            }
                        }
                        else if(thisUnit.type_of_unit_by_size__c == 'Nest'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Nest_Sold_1_to_10 = Nest_Sold_1_to_10+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Nest_Sold_11_to_20 = Nest_Sold_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Nest_Sold_21_to_30 = Nest_Sold_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Nest_Sold_31_plus = Nest_Sold_31_plus + 1; 
                            }
                        }
                    }
                    if(thisUnit.Unit_Status__c == 'Cancelled Unit- AFS'){
                        Cancellation_Available_for_Use= Cancellation_Available_for_Use+ 1;
                        Cancellation_Available_for_Usesqft = Cancellation_Available_for_Usesqft+ thisUnit.Carpet_Area_RERA_Carpet__c;
                        if(thisUnit.type_of_unit_by_size__c == 'Haven'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Haven_NA_1_to_10  = Haven_NA_1_to_10+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Haven_NA_11_to_20 = Haven_NA_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Haven_NA_21_to_30 = Haven_NA_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Haven_NA_31_plus = Haven_NA_31_plus + 1; 
                            }
                        }
                        else if(thisUnit.type_of_unit_by_size__c == 'Nest'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Nest_NA_1_to_10  = Nest_NA_1_to_10 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Nest_NA_11_to_20  = Nest_NA_11_to_20 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Nest_NA_21_to_30  = Nest_NA_21_to_30  + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Nest_NA_31_plus  = Nest_NA_31_plus  + 1; 
                            }
                        }
                    }
                    if(thisUnit.Unit_Status__c == 'Under Cancellation'){
                        Under_Cancellation= Under_Cancellation+ 1;
                        Under_Cancellationsqft = Under_Cancellationsqft+ thisUnit.Carpet_Area_RERA_Carpet__c;
                        if(thisUnit.type_of_unit_by_size__c == 'Haven'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Haven_NA_1_to_10  = Haven_NA_1_to_10+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Haven_NA_11_to_20 = Haven_NA_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Haven_NA_21_to_30 = Haven_NA_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Haven_NA_31_plus = Haven_NA_31_plus + 1; 
                            }
                        }
                        else if(thisUnit.type_of_unit_by_size__c == 'Nest'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Nest_NA_1_to_10  = Nest_NA_1_to_10 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Nest_NA_11_to_20  = Nest_NA_11_to_20 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Nest_NA_21_to_30  = Nest_NA_21_to_30  + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Nest_NA_31_plus  = Nest_NA_31_plus  + 1; 
                            }
                        }
                    }
                    if(thisUnit.Unit_Status__c == 'Hold'){
                        Hold = Hold + 1;
                        Holdsqft = Holdsqft+ thisUnit.Carpet_Area_RERA_Carpet__c;
                        if(thisUnit.type_of_unit_by_size__c == 'Haven'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Haven_NA_1_to_10  = Haven_NA_1_to_10+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Haven_NA_11_to_20 = Haven_NA_11_to_20+ 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Haven_NA_21_to_30 = Haven_NA_21_to_30 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Haven_NA_31_plus = Haven_NA_31_plus + 1; 
                            }
                        }
                        else if(thisUnit.type_of_unit_by_size__c == 'Nest'){
                            if(thisUnit.Floor_Band__c == '0-10'){
                                Nest_NA_1_to_10  = Nest_NA_1_to_10 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '11-20'){
                                Nest_NA_11_to_20  = Nest_NA_11_to_20 + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '21-30'){
                                Nest_NA_21_to_30  = Nest_NA_21_to_30  + 1; 
                            }
                            if(thisUnit.Floor_Band__c == '31+'){
                                Nest_NA_31_plus  = Nest_NA_31_plus  + 1; 
                            }
                        }
                    }
                    
                    Total = Total + 1;
                    system.debug('Total' +Total);
                    system.debug('thisUnit.Floor_No__c ____>'+thisUnit.Floor_No__c);
                    UnitID.add(thisUnit.Id);
                    if(thisUnit.Floor_No__c != NULL){  //changes D. 09-02-2021
                        if (JMap.containsKey(decimal.valueOf(thisUnit.Floor_No__c)  )) 
                        {
                            JMap.get(decimal.valueOf(thisUnit.Floor_No__c)).add(thisUnit);
                        } else 
                        {
                            List < Product2 > unitList1 = new List < Product2 > ();
                            unitList1.add(thisUnit);
                            JMap.put(decimal.valueOf(thisUnit.Floor_No__c), unitList1);
                        }
                    }
                    
                }
                system.debug('Total :: '+Total);
                system.debug('Available_for_Sale'+Available_for_Sale +'  Available_for_Sale / Total'+Available_for_Sale / Total + '(Available_for_Sale / Total) * 100 :: '+(Available_for_Sale / Total) * 100 );
                To_be_ReleasedD = ((decimal.valueOf(To_be_Released) / decimal.valueOf(Total)) * decimal.valueOf(100)).setScale(2) ;
                Available_for_SaleD = ((decimal.valueOf(Available_for_Sale) / decimal.valueOf(Total)) * decimal.valueOf(100)).setScale(2) ; 
                Blocked_by_MgmtD =  ((decimal.valueOf(Blocked_by_Mgmt) / decimal.valueOf(Total)) * decimal.valueOf(100)).setScale(2); 
                Blocked_by_Sales_HeadD = ((decimal.valueOf(Blocked_by_Sales_Head) / decimal.valueOf(Total)) * decimal.valueOf(100)).setScale(2); 
                RefugeD =  ((decimal.valueOf(Refuge) / decimal.valueOf(Total)) * decimal.valueOf(100)).setScale(2); 
                Sold_statusD = ((decimal.valueOf(Sold_status) / decimal.valueOf(Total)) * decimal.valueOf(100)).setScale(2) ; 
                Cancellation_Available_for_UseD =  ((decimal.valueOf(Cancellation_Available_for_Use) / decimal.valueOf(Total)) * decimal.valueOf(100)).setScale(2) ; 
                Under_CancellationD = ((decimal.valueOf(Under_Cancellation) / decimal.valueOf(Total)) * decimal.valueOf(100)).setScale(2) ; 
                HoldD =  ((decimal.valueOf(Hold)/ decimal.valueOf(Total)) * decimal.valueOf(100)).setScale(2) ; 
                
                To_be_Releasedsqm = (To_be_Releasedsqft/10.764).setScale(2);
                Available_for_Salesqm=  (Available_for_Salesqft/10.764).setScale(2);
                Blocked_by_Mgmtsqm=  (Blocked_by_Mgmtsqft/10.764).setScale(2);
                Blocked_by_Sales_Headsqm=  (Blocked_by_Sales_Headsqft/10.764).setScale(2);
                Refugesqm=  (Refugesqft/10.764).setScale(2);
                Sold_statussqm=  (Sold_statussqft/10.764).setScale(2);
                Cancellation_Available_for_Usesqm=  (Cancellation_Available_for_Usesqft/10.764).setScale(2);
                Under_Cancellationsqm=  (Under_Cancellationsqft/10.764).setScale(2);
                Holdsqm =  (Holdsqft/10.764).setScale(2);      
                
                totalUnit = To_be_Released + Available_for_Sale + Blocked_by_Mgmt + Blocked_by_Sales_Head + Refuge
                    + Sold_status + Cancellation_Available_for_Use + Under_Cancellation + Hold;
                
                totalsqft = To_be_Releasedsqft + Available_for_Salesqft + Blocked_by_Mgmtsqft + Blocked_by_Sales_Headsqft 
                    + Refugesqft + Sold_statussqft + Cancellation_Available_for_Usesqft + Under_Cancellationsqft+ Holdsqft;
                totalsqft = decimal.valueOf(totalsqft).setScale(2);
                
                totalsqmt = To_be_Releasedsqm + Available_for_Salesqm + Blocked_by_Mgmtsqm + Blocked_by_Sales_Headsqm + Refugesqm +
                     Sold_statussqm + Cancellation_Available_for_Usesqm + Under_Cancellationsqm + Holdsqm;
                totalsqmt = Decimal.valueOf(totalsqmt).setScale(2);
                
                Haven_Total_Open = Haven_open_1_to_10 +Haven_open_11_to_20 +Haven_open_21_to_30+Haven_open_31_plus ;
                Haven_NA_Open = Haven_NA_1_to_10+ Haven_NA_11_to_20+Haven_NA_21_to_30+Haven_NA_31_plus;
                Haven_Sold_Open= Haven_Sold_1_to_10+Haven_Sold_11_to_20 +Haven_Sold_21_to_30 + Haven_Sold_31_plus;
                
                Nest_Total_Open= Nest_open_1_to_10 +Nest_open_11_to_20 + Nest_open_21_to_30 +Nest_open_31_plus;
                Nest_Sold_Open  =  Nest_Sold_1_to_10 + Nest_Sold_21_to_30  +Nest_Sold_11_to_20 +Nest_Sold_31_plus ;
                Nest_NA_Open  =  Nest_NA_1_to_10 +Nest_NA_11_to_20 +Nest_NA_21_to_30 +Nest_NA_31_plus  ;
                
               totalOpen = Nest_Total_Open + Haven_Total_Open;
               totalBlocked = Nest_NA_Open + Haven_NA_Open;
               totalSold = Haven_Sold_Open + Nest_Sold_Open;
                
                system.debug('Available_for_SaleD' + Available_for_SaleD + '  HoldD'+HoldD + ' Total '+Total);
                system.debug('statusWiseCountMap::'+statusWiseCountMap);
                system.debug('status count : '+statuscount);
                system.debug('Available_for_Sale ::'+Available_for_Sale+' :: Blocked_by_Mgmt ::'+Blocked_by_Mgmt +' :: Available_for_Sale ::'+Available_for_Sale+' :: Blocked_by_Sales_Head ::'+Blocked_by_Sales_Head+ ' Sold_status= 0 :: '+ Sold_status+ 'Refuge :: '+Refuge+ 'Hold'+ Hold);
                
                for(String s : statusWiseCountMap.keySet()){
                    totalofunit += statusWiseCountMap.get(s);
                    system.debug('Status  : '+s+' ||| count : '+statusWiseCountMap.get(s));
                }
                system.debug('TOTALCOUNT : '+totalofunit);
                // statusWiseCountMap.put('Total',totalofunit);
                //
                system.debug('statusWiseCountMapAfter:' + statusWiseCountMap);
                
                
                floorAscSeqList.addAll(JMap.keySet());
                floorAscSeqList.sort();
                
                for (Integer i = floorAscSeqList.size() - 1; i >= 0; i--) {
                    floorDescSeqList.add(floorAscSeqList.get(i));
                }
                System.debug('FLOOR SEQ:' + floorDescSeqList.size());
                System.debug('J Map:' + JMap);
                
                for(decimal d : JMap.keySet()){
                    if(JMap.get(d).size() >= Sizeofblock){
                        Sizeofblock = JMap.get(d).size();
                    }
                }
            }
            if(Sizeofblock != 0){
                decimal dec;
                dec = ((195+2)*Sizeofblock)+51;
                width = 'width : '+dec+'px;';
            }else{
                width = 'width : 1200px;';
            }
            return floorDescSeqList;
        }
        set;
    }
    
    // Create Quotes Logic Start
    public boolean displayPopup {get; set;}     
    // public String oppId {get; set;}
    Public String PID {get;set;}
    Public String Message {get; set;} 
    List<Quote> opportunityQuotes;
    String State = 'ERROR';
    
    public void closePopup() {        
        displayPopup = false;    
    } 
    
    public pagereference saveQuoteProducts() {   
        system.debug('saveQuoteProducts---OptyID==========='+OptyID);
        system.debug('saveQuoteProducts---PID==========='+PID);
        if(OptyID!= null){
            Opportunity opportunityDetails = new Opportunity(); //= // LTR_OpportunityDomain.fetchOpportunityDetails(OptyID);
            opportunityDetails = [Select Id, Name,StageName from opportunity where id =: OptyID];
            if(opportunityDetails/*.Distribution_Channel__c*/ == null){
                // Message = 'Please select the Distribution Channel on Opportunity before creating Quote';
                //  Message = ' Opportunity before creating Quote';
            }
            /*else if(opportunityDetails.StageName == 'Quotation Finalised'){
Message = 'You cannot create a new quote now as a quote has already been finalised';
}*/
            else{
                List<Quote> opportunityQuotes = new List<Quote>();
                //LTRQuote_Domain.fetchOpportunityQuotes(OptyID);
                opportunityQuotes = [Select Id, Name, status from quote where OpportunityId =: opportunityDetails.Id]; 
                for(Quote quotes : opportunityQuotes){
                    if(quotes.Status == 'Accepted'){
                        Message = 'You cannot create a new quote now as the customer has already accepted a quote.'; 
                        State = 'SUCCESS';
                        break;
                    }
                }
                if (state == 'ERROR') {
                    opportunityDetails.StageName = 'Quotation';
                    List<Product2> unitlists = new List<Product2>(); 
                    //allready//unitlists = LTR_ProductDomain.fetchUnitProductsForProject(PID);
                    Map<Id,Pricebook2> pbList = new Map<Id,Pricebook2>([Select id from Pricebook2 where IsStandard = true]);
                    
                    List<PricebookEntry> pbeList = [Select Id, UnitPrice, Product2Id from PricebookEntry where Pricebook2Id IN: pbList.keySet()];
                    map<Id, PricebookEntry> pbeMap = new  map<Id, PricebookEntry>();
                    for(PricebookEntry pbe : pbeList){
                        pbeMap.put(pbe.Id,pbe);
                    }
                    
                    unitlists = [SELECT Id, Name, /*Opportunity__c,*/ Saleable_Area__c,/*Payable_Within__c, Unit_Name__c,*/ Tower__c,
                                 /*Tower__r.Payable_Within__c, Tower__r.Earnest_Money_Due__c, Tower__r.Maximum_Discount__c,*/ Project__r.Name//,
                                 /*(Select Id, UnitPrice/*, Salesforce_Base_Rate__c from PricebookEntries where Pricebook2Id IN: pbList.keySet())*/ 
                                 FROM Product2 WHERE Id =: PID];
                    
                    system.debug('unitlists-------'+unitlists);
                    String priceBookId;
                    if(!Test.isRunningTest())
                        priceBookId = [select Id from Pricebook2 where isStandard = true].Id;
                    else
                        priceBookId = Test.getStandardPricebookId();
                    system.debug('priceBookId-------'+priceBookId);
                    List<Quote> quotesToBeInserted = new List<Quote>();
                    List<QuoteLineItem> quoteLineItemToBeInserted =  new List<QuoteLineItem>();
                    
                    for(Product2 selectedWrapper : unitlists){
                        system.debug('selectedWrapper.Id'+selectedWrapper.Id);
                        system.debug('PricebookEntries[0].Id'+selectedWrapper.PricebookEntries);
                        system.debug('Saleable_Area__c'+selectedWrapper.Saleable_Area__c);
                        //  system.debug('Salesforce_Base_Rate__c'+selectedWrapper.PricebookEntries[0].Salesforce_Base_Rate__c);
                        system.debug('Name'+selectedWrapper.Name);
                        system.debug('priceBookId'+priceBookId);
                        // system.debug('Payable_Within__c'+selectedWrapper.Tower__r.Payable_Within__c);
                        //  system.debug('Earnest_Money_Due__c'+selectedWrapper.Tower__r.Earnest_Money_Due__c);
                        //    system.debug('Maximum_Discount__c'+selectedWrapper.Tower__r.Maximum_Discount__c);
                        //        
                        QuoteLineItem newLineItem = new QuoteLineItem();
                        newLineItem.Product2Id = selectedWrapper.Id;
                        newLineItem.Quantity = selectedWrapper.Saleable_Area__c;
                        //newLineItem.PricebookEntryId = selectedWrapper.PricebookEntries[0].Id;
                        // newLineItem.UnitPrice = selectedWrapper.PricebookEntries[0].Salesforce_Base_Rate__c;
                        
                        string foreignKey = selectedWrapper.Id + String.valueOf(DateTime.now());
                        //  Quote referenceQuote = new Quote(Foreign_Key__c = foreignKey);                
                        //    newLineItem.Quote = referenceQuote;
                        quoteLineItemToBeInserted.add(newLineItem);
                        System.debug('*****quoteLineItemToBeInserted****'+quoteLineItemToBeInserted);
                        
                        Quote parentQuote = new Quote();
                        parentQuote.Name = selectedWrapper.Name + ' ' + Datetime.now().format('dd-MM-yyyy');
                        //   parentQuote.Inventory_Unit__c = selectedWrapper.Id;
                        parentQuote.OpportunityId = OptyID;
                        //   parentQuote.Foreign_Key__c = foreignKey;
                        parentQuote.Pricebook2Id = priceBookId;
                        /*    if(selectedWrapper.Tower__r.Payable_Within__c != null)
parentQuote.Payable_Within__c = selectedWrapper.Tower__r.Payable_Within__c;
if(selectedWrapper.Tower__r.Earnest_Money_Due__c != null)
parentQuote.Earnest_Money_Due__c = selectedWrapper.Tower__r.Earnest_Money_Due__c;
if(selectedWrapper.Tower__r.Maximum_Discount__c != null)
parentQuote.Maximum_Discount__c = selectedWrapper.Tower__r.Maximum_Discount__c;
quotesToBeInserted.add(parentQuote);       
*/
                    }   
                    SYstem.debug('****quotesToBeInserted***'+quotesToBeInserted);              
                    SYstem.debug('****quotesToBeInserted.size()***'+quotesToBeInserted.size());
                    if(quotesToBeInserted.size() > 0)
                        //  LTRQuote_Domain.insertQuotes(quotesToBeInserted);
                        
                        // SYstem.debug('****quoteLineItemToBeInserted.size()***'+quoteLineItemToBeInserted.size());
                        
                        if(quoteLineItemToBeInserted.size() > 0)
                        //    LTR_QuoteLineItemDomain.insertQuoteLineItems(quoteLineItemToBeInserted);
                        
                        if(quotesToBeInserted.size() > 0 && quoteLineItemToBeInserted.size() > 0){
                            //     LTR_OpportunityDomain.updateOpportunity(opportunityDetails);
                            Message = 'The quotes have been created successfully.';
                            system.debug('Message----'+Message);
                        }else{
                            Message = 'There was an error while creating the quotes. Beacause There was an error fetching the products Deatils.';
                            system.debug('Message----'+Message);
                        }    
                }
                return new PageReference('/apex/MyCustomLookup?pid='+PID);
            }
        } else{
            Message = 'No quotes have been Created. Beacause of Opportunity ID is NULL';   
            return new PageReference('/apex/MyCustomLookup?pid='+PID);
        }
        displayPopup = true;   
        return NULL;
    }
    
    public pagereference saveQuoteProduct() { 
        if(OptyID != NULL && OptyID!=''){
            Opportunity opportunityDetails = new Opportunity(); 
            opportunityDetails = [Select Id, Name,StageName from opportunity where id =: OptyID];
            if(opportunityDetails!=NULL){
                DirectURL = 'window.open(\'/apex/MyCustomLookup?pid='+PID+'&OptyID='+opportunityDetails.Id+'&projectsent='+projectsent+'&towersent='+towersent+'\',\'_blank\',\'height=400,location=no,resizable=yes,toolbar=no,status=no,menubar=no,scrollbars=1\', 1)';
            }
        }else{
            // Message = 'No quotes have been Created. Beacause of Opportunity ID is NULL';
            // displayPopup = true; 
            DirectURL = 'window.open(\'/apex/MyCustomLookup?pid='+PID+'&OptyID=&projectsent='+projectsent+'&towersent='+towersent+'\',\'_blank\',\'height=400,location=no,resizable=yes,toolbar=no,status=no,menubar=no,scrollbars=1\', 1)'; 
        }
        return NULL;
    }
    
    // Create Quotes Logic End    
    // 
    public static List<String> getAllProject(){
        List<String> lstProjectName = new List<String>();
        for(Project__c objProject : [select Id, Name from Project__c where Active__c = true]){
            lstProjectName.add(objProject.Name);
        }
        
        return lstProjectName;
    }  
    
    public PageReference block_hold(){
        //Product2 product = new Product2(Id = ProdId, Unit_Status__c = 'Hold');
        // update product;
        system.debug('ProdId'+ProdId);
        PageReference pageRef = new PageReference('/apex/BlockPage?pid='+ProdId+'&OptyID='+OptyID);
        return pageRef;
    }
    // floorDescSeqList
    public PageReference refresh(){
        PageReference pageRef = new PageReference('/apex/S_InventoryMatrixview?projectsent='+projectsent+'&towersent='+towersent);
        pageRef.setRedirect(true);
        return pageRef;
    }
    public void closePopup1() {
        displayPopup1 = false;
    }
    
    public void showPopup1() {
        displayPopup1 = true;
    }
    
    public static boolean saveProductToQuoteCtrl1(Product2 prod,String QuoteId){
        //Code to add Price Book Id to Quote.
        Pricebook2 pricebook = [select Id,IsActive,Name,IsStandard from pricebook2 where IsStandard=true AND IsActive=true];
        quote quoteobj = [select id,name from Quote where id=:QuoteId];
        quoteobj.Pricebook2Id = pricebook.Id;
        quoteobj.Tower__c = prod.Tower__c;
        quoteobj.Project__c = prod.Project__c;
       quoteobj.Agreement_Value__c=108972.5;
        //Code to insert the Quote Line Items.
        Map<Id, PriceBookEntry> mapProductIdToPriceBook = new Map<Id, PriceBookEntry>();
        for(Product2 objProduct : [select Id from Product2 where (Id =: prod.Id OR Inventory_Master__c =: prod.Material_Code__c OR (Family = 'Other Charges' and Tower__c =: prod.Tower__c)) and IsActive=true]){
            mapProductIdToPriceBook.put(objProduct.Id, null);
        }
        
        for(PriceBookEntry objPriceBookEntry : [select Id,Name, Floor_Rise_Charges__c,Quantity__c,CGST__c,SGST__c,Product2.Description,Product2.Family,Product2.Saleable_Area__c,Product2.Carpet_Area_RERA_Carpet__c,IsActive,Product2Id,Product2.Tower__c,UnitPrice from PriceBookEntry where Product2Id in: mapProductIdToPriceBook.keyset()]){
            mapProductIdToPriceBook.put(objPriceBookEntry.Product2Id, objPriceBookEntry);
        }
        System.debug('>>>>mapProductIdToPriceBook>>'+mapProductIdToPriceBook);
        Set<String> setProdDescription = new Set<String>();
        for(Excluded_Other_Charges__c objExcludedOtherCharges : Excluded_Other_Charges__c.getAll().values()){
            setProdDescription.add(objExcludedOtherCharges.Product_Description__c);
        }
        
        List<QuoteLineItem> lstQuoteLineItem = new List<QuoteLineItem>();
        for(Id productId : mapProductIdToPriceBook.keyset()){
            PriceBookEntry objPriceBookEntry = mapProductIdToPriceBook.get(productId);
            if(objPriceBookEntry != null){
                QuoteLineItem objQuoteLineItem = new QuoteLineItem();
                objQuoteLineItem.QuoteId = QuoteId;
                objQuoteLineItem.Quantity = ((prod.Id == productId || objPriceBookEntry.Quantity__c == 2)?prod.Carpet_Area_RERA_Carpet__c:objPriceBookEntry.Quantity__c);
                objQuoteLineItem.Unit_No__c = (prod.Id == productId?null:objPriceBookEntry.Quantity__c);
                objQuoteLineItem.Product2Id = productId;
                objQuoteLineItem.UnitPrice = objPriceBookEntry.UnitPrice;// + (objPriceBookEntry.Floor_Rise_Charges__c == null?0:objPriceBookEntry.Floor_Rise_Charges__c);
                objQuoteLineItem.PricebookEntryId =  objPriceBookEntry.Id; 
                objQuoteLineItem.Tower__c = prod.Tower__c;
                // objQuoteLineItem.Product_Description__c = objPriceBookEntry.Product2.Description;
                
                if(objPriceBookEntry.Product2.Family == 'Other Charges'){
                    Decimal gstPercentage = (objPriceBookEntry.CGST__c == null?0:objPriceBookEntry.CGST__c) + (objPriceBookEntry.SGST__c == null?0:objPriceBookEntry.SGST__c);
                    Decimal gstOnOtherCharge = ((((objPriceBookEntry.UnitPrice == null?0:objPriceBookEntry.UnitPrice) * ((prod.Id == productId || objPriceBookEntry.Quantity__c == 2)?prod.Carpet_Area_RERA_Carpet__c:objPriceBookEntry.Quantity__c)) * gstPercentage) / 100);
                    
                    objQuoteLineItem.GST_on_Other_Charges2__c = gstOnOtherCharge;
                }
                Boolean excluded = false;
                for(String prodDesc : setProdDescription){
                    if(objPriceBookEntry.Product2.Description != null && objPriceBookEntry.Product2.Description.containsIgnoreCase(prodDesc)){
                        excluded = true;
                        break;
                    }
                }
                objQuoteLineItem.Excluded__c = excluded;
                if(prod.Id != productId){
                    objQuoteLineItem.Possession_Charges_GST_Included__c =  ((objPriceBookEntry.UnitPrice * objQuoteLineItem.Quantity ) * (1+  (((objPriceBookEntry.CGST__c == null?0:objPriceBookEntry.CGST__c) + (objPriceBookEntry.SGST__c == null?0:objPriceBookEntry.SGST__c)) / 100)));   
                }            
                lstQuoteLineItem.add(objQuoteLineItem);
            }            
        }
        try{
            update quoteobj;
            insert lstQuoteLineItem;
            return true;
        }catch(Exception ex){
            system.debug('Exception while inserting quote line'+ex.getMessage());
            return false;
        }
    }
    
    public void ShowDashboard(){
        if(isRendered == true){
            isRendered = false;
            //ShowDashboardStr = 'Hide Dashboard';
            system.debug('isRendered :: '+isRendered);
        }else{
            //ShowDashboardStr = 'Show Dashboard';
            isRendered = true;
            system.debug('isRendered :: '+isRendered);
        }
    }
    
    /* public string ShowDashboardStr {
get {
string sd = 'Show Dashboard';
if(isRendered == true){
sd = 'Hide Dashboard';
}
return sd;
}
set;
}*/
    
    /*
Reports.ReportDescribeResult descRes = Reports.ReportManager.describeReport('00ON00000019ktdMAA');
List<string> availableColumnFilters = new List<string>();

for (Reports.ReportTypeColumnCategory category : descRes.getReportTypeMetadata().getCategories()) {
for (Reports.ReportTypeColumn col : category.getColumns().values()) {
if (col.getFilterable()) {
system.debug('cf'+col);
}
}
}
system.debug('availableColumnFilters :: '+availableColumnFilters);

*/
    public class AnalyticChart{
        string  column;
        string operator;
        string value;
    }  
    
    public void refreshDashbord(){
        serialiseString = JSON.serialize(acList) ;
    }
    
    public class CategoryUnit{
        integer open_1_to_10;
        integer open_11_to_20;
        integer open_21_to_30;
        integer open_31_plus;
        integer Total_Open;
        
        integer Sold_1_to_10;
        integer Sold_11_to_20;
        integer Sold_21_to_30;
        integer Sold_31_plus;
        integer Sold_Open;
        
        integer NA_1_to_10;
        integer NA_11_to_20;
        integer NA_21_to_30;
        integer NA_31_plus;
        integer NA_Open;
    }
    
}
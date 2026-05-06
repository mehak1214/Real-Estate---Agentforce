trigger ARC_PPDInstallmentProgressionTrigger on AR_PPD_Installment_Progression_Event__e (after insert) {    
        if(Trigger.isafter && Trigger.isInsert){
            AR_PPDProgressionTriggerHandler.updateProgressStatus(Trigger.new);
    }
}
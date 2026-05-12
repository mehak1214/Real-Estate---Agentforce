trigger BookingTrigger on Booking_Unit__c (after insert, after update) {

    // After Insert: Set Active status and update Unit to Sold
    if(Trigger.isInsert){
        BookingTriggerHandler.activateBookingAndUpdateUnit(Trigger.new);
    }

    List<Booking_Unit__c> eligibleBookings = new List<Booking_Unit__c>();

    for(Booking_Unit__c b : Trigger.new){

        // Check status = Complete
        if(b.Booking_Status__c == 'Complete'){

            // For update → only when status changed
            if(Trigger.isUpdate){
                Booking_Unit__c oldRec = Trigger.oldMap.get(b.Id);
                if(oldRec.Booking_Status__c != 'Complete'){
                    eligibleBookings.add(b);
                }
            }
            else{
                eligibleBookings.add(b);
            }
        }
    }

    if(!eligibleBookings.isEmpty()){
        BookingTriggerHandler.createSalesOrders(eligibleBookings);
    }
}
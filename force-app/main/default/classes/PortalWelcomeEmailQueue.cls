public class PortalWelcomeEmailQueue implements Queueable {

    private List<Id> userIds;

    public PortalWelcomeEmailQueue(List<Id> userIds){
        this.userIds = userIds;
    }

    public void execute(QueueableContext context){

        for(Id userId : userIds){
            try {
                System.resetPassword(userId, true);
            } catch(Exception e){
                System.debug('Password email failed for UserId: ' + userId + ' Error: ' + e.getMessage());
            }
        }
    }
}
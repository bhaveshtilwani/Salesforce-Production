/**
 * Created by adam.mccune on 2/21/23.
 */

public with sharing class GroupDataAccess {
    public static List<Group> getGroupsWithMembersByIds(Set<Id> groupIds) {
        return new List<Group>([
                SELECT Id, (SELECT UserOrGroupId FROM GroupMembers)
                FROM Group
                WHERE Id IN :groupIds
        ]);
    }
}
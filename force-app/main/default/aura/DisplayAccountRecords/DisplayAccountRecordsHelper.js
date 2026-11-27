({
    getAccountRecord: function (component) {
        var action = component.get("c.getAccountRecord");
        var artId = component.get("v.recordId");

        action.setParams({
            "artId": artId
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS")
                component.set("v.accLst", response.getReturnValue());
        });
        $A.enqueueAction(action);
    }
})
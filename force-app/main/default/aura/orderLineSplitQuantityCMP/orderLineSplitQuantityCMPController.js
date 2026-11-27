({
    showtoastmessage : function(component, event, helper) {
        var errmessage = event.getParam('value');
        console.log(errmessage);
        component.set("v.message",errmessage);
        var myEvent = $A.get("e.c:sendMessageToVFPageEVT");
        myEvent.setParams({
            message:errmessage
        });
        myEvent.fire();
    },
    navigatetoobject: function(component, event, helper) {
        var tempobj = event.getParam('obj');
        console.log(tempobj);
        component.set("v.obj",tempobj);
        var myobjEvent = $A.get("e.c:sendMessageToVFPageEVT");
        myobjEvent.setParams({
            obj:tempobj,
            message:''

        });
        myobjEvent.fire();
    }
})
({
	doInit: function(component , event , helper){
        var action = component.get("c.updateDetails");
        action.setParams({ recordId : component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('State::::', state);
            let resBody = response.getReturnValue();
            if(resBody == 'SUCCESS'){
                $A.get('e.force:refreshView').fire();
           	$A.get("e.force:closeQuickAction").fire();
            }else{
                component.set('v.status', resBody ? resBody : 'Material Not Found');
            }
            
        });
        $A.enqueueAction(action);
    }
})
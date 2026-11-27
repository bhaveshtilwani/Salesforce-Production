({
	doInit: function(component , event , helper){
        var allowedRecordTypes = $A.get("$Label.c.Allowed_Record_Types");
        console.log('Allowed Record Types::::', allowedRecordTypes);
        var ref = component.get("v.pageReference");
        var state = ref.state;
        console.log('State Data::::',state);
        console.log('State Data:::2:',JSON.stringify(state));
        var context = state.inContextOfRef;
        var recTypeId = state.recordTypeId;
        if (context != undefined && context.startsWith("1\.")) {
            context = context.substring(2);
            var addressableContext = JSON.parse(window.atob(context));
            console.log('addressableContext----->'+JSON.stringify(addressableContext));   // you can get your recordId and other things here.
            var recId= addressableContext.attributes.recordId;
            console.log(recId);
        }
       
        console.log('recId: ',recId);
        if(recTypeId && allowedRecordTypes && allowedRecordTypes.includes(recTypeId)){//recTypeId == '0123I000000MMIyQAO'
            var pageReference = {
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'New_Account'
            },
            state: {
                c__recordTypeId: recTypeId,
            }
        };
        component.set("v.pageReference", pageReference);
        const navService = component.find('navService');
        const pageRef = component.get('v.pageReference');
        const handleUrl = (url) => {
            window.open(url,"_self");
        };
        const handleError = (error) => {
            console.log(error);
        };
        navService.generateUrl(pageRef).then(handleUrl, handleError);
        }else{
            var pageReference = {
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Account",
                actionName: "new",
                recordTypeId: recTypeId,
                nooverride : 1
            },
            state: {
                c__recordTypeId: recTypeId,
                recordTypeId: recTypeId,
                nooverride : 1
            }
        }
           component.set("v.pageReference", pageReference);
        const navService = component.find('navService');
        const pageRef = component.get('v.pageReference');
        const handleUrl = (url) => {
            window.open(url,"_self");
        };
        const handleError = (error) => {
            console.log(error);
        };
            window.location = '/001/e?RecordType='+recTypeId + '&nooverride=1';
        }
		
    }
})
({
    doInit: function (component, event, helper) {
        helper.getAccountRecord(component);
    },

    handleRowClick: function (component, event, helper) {
        var clickedRow = event.currentTarget;
        var recordId = clickedRow.getAttribute("data-id");
        var recordUrl = "/lightning/r/Account/" + recordId + "/view";

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": recordUrl,
            "isredirect": "true"
        });
        urlEvent.fire();
    }
})
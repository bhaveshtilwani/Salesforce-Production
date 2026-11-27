({
    doInitHelper : function(component, event, helper) {
        component.set("v.isRendered",false);
        var myPageRef = component.get("v.pageReference");
        
        var quoteResult = myPageRef.state.c__quoteResult;
        component.set("v.quoteResult", quoteResult);
        
        var site = myPageRef.state.c__siteType;
        component.set("v.site", site);

        var siteId = myPageRef.state.c__siteId;
        component.set("v.siteId", siteId);

        var orderType = myPageRef.state.c__orderType;
        component.set("v.orderType", orderType);

        var isUnquoted = myPageRef.state.c__isUnquoted;
        component.set("v.isUnquoted", isUnquoted);

        var searchAcctId = myPageRef.state.c__searchAcctId;
        component.set("v.searchAcctId", searchAcctId);
        
        var searchAccName = myPageRef.state.c__searchAccName;
        component.set("v.searchAccName", searchAccName);

        var orderNumber = myPageRef.state.c__orderNumber;
        component.set("v.orderNumber", orderNumber);
        
        var isRedirected  = myPageRef.state.c__isRedirected;
        component.set("v.isRedirected", isRedirected);

        component.set("v.isRendered",true);
    }
})
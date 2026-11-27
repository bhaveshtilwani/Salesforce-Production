public class BooleanExpression {
    static final Map<String, String> logicTypes = new Map<String, String>();
    static final Map<String, Map<String, String>> expressionLogic = new Map<String, Map<String, String>>();

    public static Boolean eval(String expression) {
        // If expression contains all TRUE or FALSE
        if(expression.containsNone('FALSE')) { return true; }
        if(expression.containsNone('TRUE')) { return false; }

        fillLogic();

        Boolean result = Boolean.valueOf(evaluateExpression(expression.toUpperCase()));
        System.debug('result of eval: ' + result);
        return result;
    }

    public static String evaluateExpression(String expression) {
        System.debug('***** expression: ' + expression);
        for(String logicType : logicTypes.keySet()) {
            System.debug('***** logicType: ' + logicType);
            if(expression.contains(logicType)) {
                expression = simplifyExpression(expression, logicTypes.get(logicType));
            }
        }

        if(expression.contains('AND') || expression.contains('OR') || expression.contains('(')) {
            expression = evaluateExpression(expression);
        }

        System.debug('final expression: ' + expression);
        return expression;
    }

    public static String simplifyExpression(String expression, String LogicType){
        System.debug('simplify expression...');
        Map<String, String> Logic = new Map<String, String>(expressionLogic.get(LogicType));
        System.debug('related logic for logic type: ' + Logic);
        for(String key : Logic.keySet()) {
            System.debug('key: ' + key);
            expression = expression.replace(key, Logic.get(key));
            System.debug('expression after replace: ' + expression);
        }

        return expression;
    }

    /**
    * Fill AND and OR Logic
    *
    */
    public static void fillLogic() {
        Map<String, String> ANDLogic = new Map<String, String>();
        Map<String, String> ORLogic = new Map<String, String>();
        Map<String, String> BRACELogic = new Map<String, String>();

        logicTypes.put('AND', 'AND');
        logicTypes.put('OR', 'OR');
        logicTypes.put('(', 'BRACES');

        // AND Logic
        ANDLogic.put('TRUE AND TRUE', 'TRUE');
        ANDLogic.put('TRUE AND FALSE', 'FALSE');
        ANDLogic.put('FALSE AND TRUE', 'FALSE');
        ANDLogic.put('FALSE AND FALSE', 'FALSE');
        expressionLogic.put('AND', ANDLogic);

        // OR Logic
        ORLogic.put('TRUE OR TRUE', 'TRUE');
        ORLogic.put('TRUE OR FALSE', 'TRUE');
        ORLogic.put('FALSE OR TRUE', 'TRUE');
        ORLogic.put('FALSE OR FALSE', 'FALSE');
        expressionLogic.put('OR', ORLogic);

        // Braces Logic
        BRACELogic.put('(TRUE)', 'TRUE');
        BRACELogic.put('(FALSE)', 'FALSE');
        expressionLogic.put('BRACES', BRACELogic);
    }
}
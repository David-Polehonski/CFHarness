component name="TestResult" output="false" {
    public TestResult function init (required string testString, required struct r) {
        
        VARIABLES.test = testString;

        VARIABLES.result = r.result;
        
        if (structKeyExists(r, 'reason')) {
            VARIABLES.reason = r.reason;
        } else{ 
            VARIABLES.reason = "";
        }
        
        switch (r.result) {
        case "Passed":
            REQUEST.passed += 1;
            break;
        case "Failed":
            REQUEST.failed += 1;
            break;
        }
                
        return THIS;
    }
    public string function getTest() {
        return VARIABLES.test;
    }
    
    public string function getResult() {
        return VARIABLES.result;
    }
    
    public string function getReason() {
        return VARIABLES.reason;
    }

}
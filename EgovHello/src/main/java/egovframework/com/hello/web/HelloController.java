package egovframework.com.hello.web;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/a/b/c")
public class HelloController {
    
    private static final Logger LOGGER = LoggerFactory.getLogger(HelloController.class);
    
    @Value("${FORCE_ERROR:false}")
    private boolean forceError;
    
    @GetMapping("/hello")
    public String hello() {
        LOGGER.info("Hello API called");
        
        if (forceError) {
            LOGGER.error("Forcing 500 error as configured");
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Forced error");
        }
        
        return "Hello from EgovFramework!";
    }
}

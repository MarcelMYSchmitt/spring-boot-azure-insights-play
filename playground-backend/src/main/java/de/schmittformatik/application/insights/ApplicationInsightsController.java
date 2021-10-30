package de.schmittformatik.application.insights;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.microsoft.applicationinsights.telemetry.Duration;
import com.microsoft.applicationinsights.TelemetryClient;

import io.micrometer.core.annotation.Timed;

import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;

import java.io.IOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
public class ApplicationInsightsController {

	@Value("${MySecretSecretName}")
	private String mySecretSecretName;

	@Value("${AppInsightsKey}")
	private String appInsightsKey;	

	@Value("${SERVICEBUSDESTINATIONNAME}")
	private String serviceBusDestinationName;	
	
    @Autowired
	private TelemetryClient telemetryClient;
    
    @Autowired
    private JmsTemplate jmsTemplate;
    
    private CloseableHttpClient closeableHttpClient = HttpClients.createDefault();
    
	private final Logger log = LoggerFactory.getLogger(ApplicationInsightsController.class);

    @GetMapping("/helloworld")
    public String hello() {
       log.info("hello world!");
       return "Hello World!";
    }
    
    @GetMapping("/trackschmittformatik")
    public int trackdependency() throws IOException {
        HttpGet httpGet = new HttpGet("https://www.schmittformatik.de");
        int status;
        try (CloseableHttpResponse response = closeableHttpClient.execute(httpGet)) {
            status = response.getStatusLine().getStatusCode();
        
            // track a custom dependency with no real value
            telemetryClient.trackDependency("schmittformatik", "Get", new Duration(0, 0, 1, 1, 1), true);
        }
        return status;
    }

    @GetMapping("/trackexception")
    public String trackexeption() {
        trackexception();
        return "Ups, something went wrong!";
    }
    
    @GetMapping("/trackunhandledexpection")
    public String unhandlednpe() {
        throw new NullPointerException();
    }
    
    @GetMapping("/trackmetric")
    public String trackmetric() {
        // track a custom metric
        telemetryClient.trackMetric("CUSTOM_METRIC_100", 100);
        return "Tracked custom metric.";
    } 

    @GetMapping("/trackevent")
    public String trackevent() {
        // track a custom event
        telemetryClient.trackEvent("Sending a custom event.");
        return "Tracked custom event.";
    }

    @GetMapping("/tracktrace")
    public String tracktrace() {
        // trace a custom trace
        telemetryClient.trackTrace("Sending a custom trace.");
        return "Tracked custom trace.";
    }

    @GetMapping("/trackslow")
    public String trackslow() {
        slow();
        return "Slow call without custom metric.";
    }

    // custom metric called 'CUSTOM_METRIC_SLOWCALL
    @GetMapping("/slow")
    @Timed("CUSTOM_METRIC_SLOWCALL")
    public String slowcall() {
        slow();
        return "Slow call with custom metric called 'CUSTOM_METRIC_SLOWCALL'.";
    }

    // Key Vault 
    @GetMapping("/mysecretsecretname")
    public String getMySecretSecretName() {
        return mySecretSecretName;
    }    

    @GetMapping("/appinsightskey")
    public String getAppInsightsKey() {
        return appInsightsKey;
    }    
    
    // Service Bus Topic
    @PostMapping("/messages")
    public String postMessage(@RequestParam String message) {
        log.info("Sending service bus test message...");
        jmsTemplate.convertAndSend(serviceBusDestinationName, new ServiceBusTestMessage(message));
        return message;
    }

    // helper
    public void slow()  {
        try {
            Thread.sleep(2000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
    
    public void trackexception()  {
        try {
            throw new NullPointerException();
        } catch (Exception ex) {
            telemetryClient.trackException(ex);
            ex.printStackTrace();
        }
    }
}
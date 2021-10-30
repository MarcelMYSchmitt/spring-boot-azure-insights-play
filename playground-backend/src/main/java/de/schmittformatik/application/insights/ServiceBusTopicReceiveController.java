package de.schmittformatik.application.insights;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
public class ServiceBusTopicReceiveController {

    private final Logger log = LoggerFactory.getLogger(ServiceBusTopicReceiveController.class);

    @JmsListener(destination = "${SERVICEBUSTOPICNAME}", containerFactory = "topicJmsListenerContainerFactory",
            subscription = "${SERVICEBUSSUBSCRIPTIONNAME}")
    public void receiveMessage(ServiceBusTestMessage serviceBusTestMessage) {
        log.info("Received service bus test message: {}", serviceBusTestMessage.getContent());
    }
}
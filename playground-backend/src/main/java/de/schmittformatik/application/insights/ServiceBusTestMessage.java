package de.schmittformatik.application.insights;

import java.io.Serializable;

public class ServiceBusTestMessage implements Serializable {

    private static final long serialVersionUID = -295422703255886286L;

    private String content;

    public ServiceBusTestMessage() {
    }

    public ServiceBusTestMessage(String content) {
        setContent(content);
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

}
package com.example.demo.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DebugController {

    @GetMapping("/debug/actuator")
    public Map<String, String> debugActuator() {
        Map<String, String> debug = new HashMap<>();
        debug.put("status", "Debug endpoint working");
        debug.put("management.endpoints.web.exposure.include", 
                 System.getProperty("management.endpoints.web.exposure.include", "not set as system property"));
        return debug;
    }
}
package com.example.demo.controller;

import java.util.concurrent.CompletableFuture;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class LoadTestController {

    @GetMapping("/stress/cpu")
    public String stressCpu(@RequestParam(defaultValue = "30") int seconds,
                           @RequestParam(defaultValue = "4") int threads) {
        
        long endTime = System.currentTimeMillis() + (seconds * 1000);
        
        // Start multiple CPU-intensive threads
        for (int i = 0; i < threads; i++) {
            CompletableFuture.runAsync(() -> {
                while (System.currentTimeMillis() < endTime) {
                    // CPU-intensive calculation
                    Math.sqrt(Math.random() * 1000000);
                }
            });
        }
        
        return String.format("CPU stress test started: %d threads for %d seconds", threads, seconds);
    }
    
    @GetMapping("/stress/memory")
    public String stressMemory(@RequestParam(defaultValue = "100") int sizeMB) {
        try {
            byte[][] arrays = new byte[sizeMB][];
            for (int i = 0; i < sizeMB; i++) {
                arrays[i] = new byte[1024 * 1024]; // 1MB each
                // Fill with data to prevent optimization
                for (int j = 0; j < arrays[i].length; j += 1024) {
                    arrays[i][j] = (byte) i;
                }
            }
            
            // Hold memory for a while
            Thread.sleep(60000);
            
            return String.format("Memory stress test completed: %d MB allocated", sizeMB);
        } catch (Exception e) {
            return "Memory stress test failed: " + e.getMessage();
        }
    }
    
    @GetMapping("/health/check")
    public String healthCheck() {
        return "Application is running - " + System.currentTimeMillis();
    }
}
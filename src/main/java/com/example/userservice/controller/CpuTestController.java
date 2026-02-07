package com.example.userservice.controller;

import java.util.stream.IntStream;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CpuTestController {
    @GetMapping("/api/points/cpu-test")
    public String cpuTest() {
        IntStream.range(0, 2).parallel().forEach(i -> {
            long sum = 0;
            for (long j = 0; j < 500_000_000L; j++) {
                sum += j;
            }
        });
        return "ok";
    }
}

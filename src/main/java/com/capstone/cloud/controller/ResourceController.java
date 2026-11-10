package com.capstone.cloud.controller;

import com.capstone.cloud.model.ResourceItem;
import com.capstone.cloud.repository.ResourceItemRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/resources")
public class ResourceController {

    private final ResourceItemRepository repository;

    public ResourceController(ResourceItemRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<ResourceItem> getAllResources() {
        return repository.findAll();
    }

    @PostMapping
    public ResponseEntity<ResourceItem> createResource(@RequestBody ResourceItem item) {
        return ResponseEntity.ok(repository.save(item));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteResource(@PathVariable Long id) {
        if (!repository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        repository.deleteById(id);
        return ResponseEntity.ok(Map.of("message", "Resource deleted successfully by Admin"));
    }
}

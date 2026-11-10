package com.capstone.cloud.repository;

import com.capstone.cloud.model.ResourceItem;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ResourceItemRepository extends JpaRepository<ResourceItem, Long> {
}

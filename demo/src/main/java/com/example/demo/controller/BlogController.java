package com.example.demo.controller;

import com.example.demo.dto.BlogRequest;
import com.example.demo.entity.Blog;
import com.example.demo.entity.User;
import com.example.demo.repository.BlogRepository;
import com.example.demo.repository.UserRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/blogs")
@CrossOrigin(origins = "*", maxAge = 3600)
public class BlogController {

    @Autowired
    private BlogRepository blogRepository;

    @Autowired
    private UserRepository userRepository;

    @GetMapping
    public ResponseEntity<List<Blog>> getAllBlogs() {
        List<Blog> blogs = blogRepository.findAll();
        return ResponseEntity.ok(blogs);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Blog> getBlogById(@PathVariable Long id) {
        Optional<Blog> blog = blogRepository.findById(id);
        if (blog.isPresent()) {
            return ResponseEntity.ok(blog.get());
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/my-blogs")
    public ResponseEntity<List<Blog>> getMyBlogs() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        User currentUser = userRepository.findByUsername(currentUsername).get();
        
        List<Blog> userBlogs = blogRepository.findByAuthor(currentUser);
        return ResponseEntity.ok(userBlogs);
    }

    @PostMapping
    public ResponseEntity<Blog> createBlog(@Valid @RequestBody BlogRequest blogRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        User currentUser = userRepository.findByUsername(currentUsername).get();

        Blog blog = new Blog(blogRequest.getTitle(), blogRequest.getContent(), currentUser);
        Blog savedBlog = blogRepository.save(blog);
        return ResponseEntity.ok(savedBlog);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Blog> updateBlog(@PathVariable Long id, @Valid @RequestBody BlogRequest blogRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        User currentUser = userRepository.findByUsername(currentUsername).get();

        Optional<Blog> blogOptional = blogRepository.findById(id);
        if (blogOptional.isPresent()) {
            Blog blog = blogOptional.get();
            
            // Users can only update their own blogs, or admin can update any blog
            if (!blog.getAuthor().getId().equals(currentUser.getId()) && 
                !currentUser.getRole().name().equals("ADMIN")) {
                return ResponseEntity.status(403).build();
            }

            blog.setTitle(blogRequest.getTitle());
            blog.setContent(blogRequest.getContent());
            return ResponseEntity.ok(blogRepository.save(blog));
        }
        return ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteBlog(@PathVariable Long id) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUsername = authentication.getName();
        User currentUser = userRepository.findByUsername(currentUsername).get();

        Optional<Blog> blogOptional = blogRepository.findById(id);
        if (blogOptional.isPresent()) {
            Blog blog = blogOptional.get();
            
            // Users can only delete their own blogs, or admin can delete any blog
            if (!blog.getAuthor().getId().equals(currentUser.getId()) && 
                !currentUser.getRole().name().equals("ADMIN")) {
                return ResponseEntity.status(403).build();
            }

            blogRepository.deleteById(id);
            return ResponseEntity.ok().build();
        }
        return ResponseEntity.notFound().build();
    }
}
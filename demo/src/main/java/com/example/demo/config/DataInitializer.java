package com.example.demo.config;

import com.example.demo.entity.User;
import com.example.demo.entity.Blog;
import com.example.demo.repository.UserRepository;
import com.example.demo.repository.BlogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BlogRepository blogRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // Create admin user
        if (!userRepository.existsByUsername("admin")) {
            User admin = new User("admin", "admin@example.com", passwordEncoder.encode("admin123"));
            admin.setRole(User.Role.ADMIN);
            userRepository.save(admin);
        }

        // Create regular user
        if (!userRepository.existsByUsername("user")) {
            User user = new User("user", "user@example.com", passwordEncoder.encode("user123"));
            user.setRole(User.Role.USER);
            userRepository.save(user);
        }

        // Create sample blogs
        if (blogRepository.count() == 0) {
            User user = userRepository.findByUsername("user").get();
            User admin = userRepository.findByUsername("admin").get();

            Blog blog1 = new Blog("First Blog Post", "This is the content of the first blog post.", user);
            Blog blog2 = new Blog("Admin's Blog", "This is an admin blog post.", admin);
            Blog blog3 = new Blog("User's Second Post", "Another interesting blog post by the user.", user);

            blogRepository.save(blog1);
            blogRepository.save(blog2);
            blogRepository.save(blog3);
        }
    }
}
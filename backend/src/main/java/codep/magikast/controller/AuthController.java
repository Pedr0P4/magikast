package codep.magikast.controller;

import codep.magikast.dto.AuthRequest;
import codep.magikast.dto.AuthResponse;
import codep.magikast.model.Account;
import codep.magikast.repository.AccountRepository;
import codep.magikast.security.JwtUtil;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;
    private final AccountRepository accountRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthController(AuthenticationManager authenticationManager, JwtUtil jwtUtil, 
                          AccountRepository accountRepository, PasswordEncoder passwordEncoder) {
        this.authenticationManager = authenticationManager;
        this.jwtUtil = jwtUtil;
        this.accountRepository = accountRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody AuthRequest request) {
        try {
            Authentication auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getUser(), request.getPassword())
            );

            String token = jwtUtil.generateToken(auth.getName());
            return ResponseEntity.ok(new AuthResponse(token, "Login successful"));
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(401).body(new AuthResponse(null, "Invalid username or password"));
        }
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody AuthRequest request) {
        Optional<Account> existingUser = accountRepository.findByUser(request.getUser());
        
        if (existingUser.isPresent()) {
            return ResponseEntity.badRequest().body(new AuthResponse(null, "Username already exists"));
        }

        Account newAccount = new Account();
        newAccount.setId(UUID.randomUUID().toString());
        newAccount.setUser(request.getUser());
        newAccount.setPassword(passwordEncoder.encode(request.getPassword()));
        newAccount.setMatches(0);
        newAccount.setVictories(0);
        newAccount.setStreak(0);
        newAccount.setMaxStreak(0);

        accountRepository.save(newAccount);

        String token = jwtUtil.generateToken(newAccount.getUser());
        return ResponseEntity.ok(new AuthResponse(token, "User registered successfully"));
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        return ResponseEntity.ok(new AuthResponse(null, "Logout successful. Please discard your token on the client."));
    }

    @GetMapping("/verify")
    public ResponseEntity<?> verify(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(401).body(new AuthResponse(null, "No token provided"));
        }

        String token = authHeader.substring(7);
        try {
            String username = jwtUtil.validateTokenAndRetrieveSubject(token);
            if (accountRepository.findByUser(username).isPresent()) {
                return ResponseEntity.ok(new AuthResponse(token, "Token is valid"));
            } else {
                return ResponseEntity.status(401).body(new AuthResponse(null, "User does not exist anymore"));
            }
        } catch (Exception e) {
            return ResponseEntity.status(401).body(new AuthResponse(null, "Invalid or expired token"));
        }
    }
}

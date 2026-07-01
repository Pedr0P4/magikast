package codep.magikast.controller;

import codep.magikast.dto.AuthRequest;
import codep.magikast.dto.AuthResponse;
import codep.magikast.dto.MatchResultRequest;
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

@CrossOrigin("*")
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

    private AuthResponse createAuthResponse(String token, String message, Account account) {
        if (account == null) {
            return new AuthResponse(token, message);
        }
        String displayName = (account.getDisplayName() != null && !account.getDisplayName().isEmpty()) ? account.getDisplayName() : account.getUser();
        return new AuthResponse(token, message, account.getUser(), displayName, account.getMatches(), account.getVictories(), account.getStreak(), account.getMaxStreak());
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody AuthRequest request) {
        try {
            Authentication auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getUser(), request.getPassword())
            );

            String token = jwtUtil.generateToken(auth.getName());
            Account account = accountRepository.findByUser(auth.getName()).orElse(null);
            return ResponseEntity.ok(createAuthResponse(token, "Login successful", account));
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
        String displayName = (request.getDisplayName() != null && !request.getDisplayName().isEmpty()) ? request.getDisplayName() : request.getUser();
        newAccount.setDisplayName(displayName);
        newAccount.setMatches(0);
        newAccount.setVictories(0);
        newAccount.setStreak(0);
        newAccount.setMaxStreak(0);

        accountRepository.save(newAccount);

        String token = jwtUtil.generateToken(newAccount.getUser());
        return ResponseEntity.ok(createAuthResponse(token, "User registered successfully", newAccount));
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
            Optional<Account> accOpt = accountRepository.findByUser(username);
            if (accOpt.isPresent()) {
                return ResponseEntity.ok(createAuthResponse(token, "Token is valid", accOpt.get()));
            } else {
                return ResponseEntity.status(401).body(new AuthResponse(null, "User does not exist anymore"));
            }
        } catch (Exception e) {
            return ResponseEntity.status(401).body(new AuthResponse(null, "Invalid or expired token"));
        }
    }

    @PostMapping("/match-end")
    public ResponseEntity<?> matchEnd(@RequestHeader(value = "Authorization", required = false) String authHeader, @RequestBody MatchResultRequest request) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(401).body(new AuthResponse(null, "No token provided"));
        }
        String token = authHeader.substring(7);
        try {
            String username = jwtUtil.validateTokenAndRetrieveSubject(token);
            Optional<Account> accOpt = accountRepository.findByUser(username);
            if (accOpt.isPresent()) {
                Account account = accOpt.get();
                account.setMatches(account.getMatches() + 1);
                if (request.isWon()) {
                    account.setVictories(account.getVictories() + 1);
                    account.setStreak(account.getStreak() + 1);
                    if (account.getStreak() > account.getMaxStreak()) {
                        account.setMaxStreak(account.getStreak());
                    }
                } else {
                    account.setStreak(0);
                }
                accountRepository.save(account);
                return ResponseEntity.ok(createAuthResponse(token, "Match stats updated", account));
            } else {
                return ResponseEntity.status(401).body(new AuthResponse(null, "User not found"));
            }
        } catch (Exception e) {
            return ResponseEntity.status(401).body(new AuthResponse(null, "Invalid or expired token"));
        }
    }
}


package codep.magikast.security;

import codep.magikast.model.Account;
import codep.magikast.repository.AccountRepository;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Optional;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final AccountRepository accountRepository;

    public CustomUserDetailsService(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Optional<Account> accountOpt = accountRepository.findByUser(username);
        
        if (accountOpt.isEmpty()) {
            throw new UsernameNotFoundException("User not found: " + username);
        }

        Account account = accountOpt.get();
        return new User(account.getUser(), account.getPassword(), new ArrayList<>());
    }
}

package codep.magikast.repository;

import codep.magikast.model.Account;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Repository;

import jakarta.annotation.PostConstruct;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Repository
public class AccountRepository {

    private final String FILE_PATH = "accounts.json";
    private final ObjectMapper objectMapper = new ObjectMapper();

    public AccountRepository() {
    }

    @PostConstruct
    public void init() {
        File file = new File(FILE_PATH);
        if (!file.exists()) {
            try {
                if (file.getParentFile() != null) {
                    file.getParentFile().mkdirs();
                }
                file.createNewFile();
                objectMapper.writeValue(file, new ArrayList<Account>());
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public synchronized List<Account> findAll() {
        File file = new File(FILE_PATH);
        try {
            if (file.length() == 0) {
                return new ArrayList<>();
            }
            return objectMapper.readValue(file, new TypeReference<List<Account>>() {});
        } catch (IOException e) {
            e.printStackTrace();
            return new ArrayList<>();
        }
    }

    public synchronized void save(Account account) {
        List<Account> accounts = findAll();
        
        Optional<Account> existingAccount = accounts.stream()
                .filter(a -> a.getId().equals(account.getId()))
                .findFirst();

        if (existingAccount.isPresent()) {
            accounts.set(accounts.indexOf(existingAccount.get()), account);
        } else {
            accounts.add(account);
        }

        try {
            objectMapper.writeValue(new File(FILE_PATH), accounts);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public Optional<Account> findByUser(String user) {
        return findAll().stream()
                .filter(account -> account.getUser().equals(user))
                .findFirst();
    }
}

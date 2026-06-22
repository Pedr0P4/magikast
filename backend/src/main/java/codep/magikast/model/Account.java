package codep.magikast.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Account {
    private String id;
    private String user;
    private String password;
    private int matches;
    private int victories;
    private int streak;
    private int maxStreak;
}

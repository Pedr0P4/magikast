package codep.magikast.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    private String token;
    private String message;
    private String user;
    private String displayName;
    private int matches;
    private int victories;
    private int streak;
    private int maxStreak;

    public AuthResponse(String token, String message) {
        this.token = token;
        this.message = message;
    }
}

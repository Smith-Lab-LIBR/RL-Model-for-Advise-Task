# Model-Based Learning Agent

## Overview
The model-based learning agent aims to simulate decision-making processes by updating state transition probabilities based on the outcomes of actions taken. The agent evaluates the expected values of potential actions and uses these to guide future decisions.

---

## Note from Carter

Model-based: In this approach, the agent learns state transition probabilities. Specifically, after selecting "left" or "right" immediately, the agent learns the probability of transitioning to a "win" state or a "loss" state. When the agent consults the advisor and receives a hint to go left or right, it learns the probability of reaching a "win" state or a "loss" state depending on the side chosen. The transition probabilities are updated as follows:

p(win) = p(win) + learning_rate * [binary win/loss - p(win)]  
p(loss) = p(loss) learning_rate * [binary win/loss - p(loss)]

At each time step, the expected value of each action is calculated by multiplying the probability of being in the win state by the known reward for wins (20 or 40, depending on whether the advisor is chosen) and adding it to the probability of being in the loss state, based on the known reward for losses (either -40 or -80, depending on the game frame).

### State
The task has five main states:

1. **Start/Root**: The initial state of the agent.  
2. **Win**: The state representing a successful decision that leads to a reward.  
3. **Lose**: The state where the agent makes an incorrect decision.  
4. **Advise Left**: The state where advice suggests choosing the left option.  
5. **Advise Right**: The state where advice suggests choosing the right option.  

### Action
Each state offers three possible actions:

1. **Choose Left**: The agent chooses the left option.  
2. **Choose Right**: The agent chooses the right option.  
3. **Take Advise**: The agent decides to follow the given advice.  

---

### Time Step 1
Start from the state: **Start**

1. **Choose Left**  
   Result in:  
   - Win State with a probability  
   - Lose State with a probability  

2. **Choose Right**  
   Result in:  
   - Win State with a probability  
   - Lose State with a probability  

3. **Take Advise**  
   Result in:  
   - Advise Left State with a probability  
   - Advise Right State with a probability  

---

### Time Step 2
Start from the state: **Left Advise State**

1. **Choose Left**  
   Result in:  
   - Win State with a probability  
   - Lose State with a probability  

2. **Choose Right**  
   Result in:  
   - Win State with a probability  
   - Lose State with a probability  

---

## Probability Table
Instead of a Q-table, this approach uses a probability table for transitions:

- p(win|s=start, a=left)  
- p(loss|s=start, a=left)  
- p(win|s=start, a=right)  
- p(loss|s=start, a=right)  
- p(win|s=start, a=take advise)  
- p(loss|s=start, a=take advise)  

- p(win|s=advise left, a=left)  
- p(loss|s=advise left, a=left)  
- p(win|s=advise left, a=right)  
- p(loss|s=advise left, a=right)  

- p(win|s=advise right, a=left)  
- p(loss|s=advise right, a=left)  
- p(win|s=advise right, a=right)  
- p(loss|s=advise right, a=right)  

---

## Update Rule
No need for actual action; just update the probability table:  

p(win｜given condition) = p(win｜given condition) + learning_rate * [binary win/loss - p(win｜given condition)]  
p(loss｜given condition) = p(loss｜given condition) + learning_rate * [binary win/loss - p(loss｜given condition)]  

---

## Generate Action Probabilities
The agent generates action probabilities based on the expected value of each action. The expected value of each action is calculated by multiplying the probability of being in the win state by the known reward for wins (20 or 40, depending on whether the advisor is chosen) and adding it to the probability of being in the loss state, based on the known reward for losses (either -40 or -80, depending on the game frame). The agent then normalizes the expected values to generate action probabilities:

- **Time Step 1**: Softmax the three expected values to get the action probabilities.  
- **Time Step 2**: Softmax the two expected values to get the action probabilities.  

---

## Determine the Expectation of Taking Advice
E(take advise) = p(win|s=start, a=take advise) * 20 + p(loss|s=start, a=take advise) * -40



# Parameters

